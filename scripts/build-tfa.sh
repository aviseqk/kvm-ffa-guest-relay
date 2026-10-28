#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TFA_SRC_DIR="$ROOT/tf-a"

# Build configuration - default using all available cores
JOBS="${JOBS:-$(nproc)}"
echo "Using $JOBS parallel job(s)"

PLATFORM="${PLATFORM:-fvp}"
ARCH=aarch64
CROSS_COMPILE=aarch64-none-linux-gnu-
BUILD_BASE="$ROOT/out/tf-a"
BUILD_TYPE=debug

mkdir -p $BUILD_BASE

echo "Building TF-A for platform: $PLATFORM"

case "$PLATFORM" in 
	fvp)
		PLAT=fvp

		# UBoot artifacts
		BL33="$ROOT/out/uboot/u-boot.bin"
		# Hafnium artifacts
		BL32="$ROOT/out/hafnium/fvp/secure_aem_v8a_fvp_vhe_clang/hafnium.bin"
		SP_LAYOUT="$ROOT/configs/fvp/sp-at-el0-layout.json"
		SPMC_MANIFEST="$ROOT/ff-a-acs/platform/manifest/tgt_tfa_fvp/fvp_spmc_manifest_el0.dts"
		SP_LIST="$BUILD_BASE/$PLAT/$BUILD_TYPE/sp_list_fragment.dts"

		for f in "$BL32" "$BL33" "$SP_LAYOUT" "$SPMC_MANIFEST" ; do
			[[ -f "$f" ]] || {
				echo "ERROR: Required artifact not found: $f" >&2
				exit 1
			}
		done

		cd $TFA_SRC_DIR

		make -j"$JOBS" \
			PLAT=$PLAT ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE \
			LOG_LEVEL=50 BUILD_TYPE=$BUILD_TYPE BUILD_BASE=$BUILD_BASE \
			SPD=spmd BRANCH_PROTECTION=1 ARM_ARCH_MINOR=5 ENABLE_FEAT_MTE2=1 \
			GIC_EXT_INTID=1 CTX_INCLUDE_EL2_REGS=1 CTX_INCLUDE_PAUTH_REGS=1 \
			SPMD_SPM_AT_SEL2=1 \
			BL32="$BL32" \
			BL33="$BL33" \
			SP_LAYOUT_FILE="$SP_LAYOUT" \
			ARM_BL2_SP_LIST_DTS="$SP_LIST" \
			ARM_SPMC_MANIFEST_DTS="$SPMC_MANIFEST" \
			all fip

		echo "Generated SP list:"
		echo "  $SP_LIST"

		;;

	qemu)
		PLAT=qemu

		BL33="$ROOT/out/qemu/uboot/u-boot.bin"
		BL32="$ROOT/out/hafnium/qemu/secure_qemu_aarch64_clang/hafnium.bin"

		SP_LAYOUT="$ROOT/configs/qemu/optee-as-sp/sp_layout.json"
		SPMC_MANIFEST="$ROOT/configs/qemu/optee-as-sp/spmc_el2_manifest.dts"
		TB_FW_CONFIG="$ROOT/configs/qemu/optee-as-sp/tb_fw_config.dts"
		SP_LIST="$BUILD_BASE/$PLAT/$BUILD_TYPE/sp_list_fragment.dts"


		for f in "$BL33" "$BL32" "$SP_LAYOUT" "$SPMC_MANIFEST" "$TB_FW_CONFIG"; do
			[[ -f "$f" ]] || {
				echo "ERROR: Required artifact not found: $f" >&2
				exit 1
			}
		done

		cd "$TFA_SRC_DIR"

		# QEMU Boot: TF-A + U-Boot as BL33 + pKVM Linux + Hafnium at S-EL2 + OP-TEE as S-EL1 SPs.
		make -j"$JOBS" \
			PLAT="$PLAT" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" \
			LOG_LEVEL=50 BUILD_TYPE="$BUILD_TYPE" BUILD_BASE="$BUILD_BASE" \
			ENABLE_FEAT_SEL2=1 BRANCH_PROTECTION=1 ENABLE_FEAT_MTE2=2 \
			SPD=spmd CTX_INCLUDE_EL2_REGS=1 CTX_INCLUDE_PAUTH_REGS=1 \
			ENABLE_SME_FOR_NS=2 ENABLE_SME_FOR_SWD=1 ENABLE_SVE_FOR_NS=2 ENABLE_SVE_FOR_SWD=1 \
			ENABLE_FEAT_FGT=2 ENABLE_FEAT_HCX=2 ENABLE_FEAT_ECV=2 \
			ARM_ARCH_MAJOR=8 ARM_ARCH_MINOR=3 QEMU_USE_GIC_DRIVER=QEMU_GICV3 \
			BL32_RAM_LOCATION=tdram NEED_FDT=yes \
			SPMD_SPM_AT_SEL2=1 \
			BL32="$BL32" \
			BL33="$BL33" \
			SP_LAYOUT_FILE="$SP_LAYOUT" \
			ARM_BL2_SP_LIST_DTS="$SP_LIST" \
			QEMU_TOS_FW_CONFIG_DTS="$SPMC_MANIFEST" \
			QEMU_TB_FW_CONFIG_DTS="$TB_FW_CONFIG" \
			all fip

		QEMU_TFA_OUT="$BUILD_BASE/$PLAT/$BUILD_TYPE"
		BIOS_IMAGE="$QEMU_TFA_OUT/qemu_fw.bios"
		
		if [[ ! -f "$BIOS_IMAGE" ]]; then
			echo "Expected TF-A to build $BIOS_IMAGE" >&2
			echo "Construct the QEMU flash image from BL1 + FIP"
			exit 1
		fi
		echo "QEMU TF-A firmware image:"
		echo "  $BIOS_IMAGE"
		echo "Generated SP list:"
		echo "  $SP_LIST"

		;;

	*)
		echo "Unsupported PLATFORM='$PLATFORM'; use fvp or qemu." >&2
		exit 2
		;;

esac
