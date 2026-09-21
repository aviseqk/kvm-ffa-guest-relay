#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TFA_SRC_DIR="$ROOT/tf-a"

# Build configuration - default using all available cores
JOBS="${JOBS:-$(nproc)}"
echo "Using $JOBS parallel job(s)"

BUILD_BASE="$ROOT/out/tf-a"
PLAT=fvp
ARCH=aarch64
CROSS_COMPILE=aarch64-none-linux-gnu-
BUILD_TYPE=debug

# UBoot artifacts
#BL33="$ROOT/out/uboot/u-boot.bin"

# TEST: swap ff-a-acs's vm1.bin as BL33 with U-Boot later post staging validation check of Secure World Stack
BL33="$ROOT/out/ff-a-acs/output/vm1.bin"
if [[ ! -f "$BL33" ]]; then
	echo "ERROR: BL33 image not found!:"
	echo " $BL33"
	exit 1
fi

echo "SUCCESS: Found BL33 image:"
echo " $BL33"

# Hafnium artifacts
BL32="$ROOT/out/hafnium/secure_aem_v8a_fvp_vhe_clang/hafnium.bin"

if [[ ! -f "$BL32" ]]; then
	echo "ERROR: BL32 image not found!:"
	echo " $BL32"
	exit 1
fi

echo "SUCCESS: Found BL32 image:"
echo " $BL32"

# TODO: replace the sp-layout.json's hard-coded relative paths with a configurable path either by this build script or by templating
# NOTE: https://github.com/aviseqk/ff-a-acs/blob/main/docs/testcase_unverified.md says to use
# sp_layout_v12.json from ff-a-acs/platform/manifest/tgt_tft_fvp/ as SP_LAYOUT_FILE hence can remove our personal sp_layout file   

# NOTE: FF-A ACS's EL0 provided SP layout file: 	SP_LAYOUT="$ROOT/ff-a-acs/platform/manifest/tgt_tfa_fvp/sp_layout_el0_v12.json"
# FF-A ACS's provided SP layout file for SP at EL1: SP_LAYOUT="$ROOT/ff-a-acs/platform/manifest/tgt_tfa_fvp/sp_layout_el0_v12.json"

SP_LAYOUT="$ROOT/configs/sp-layout.json"

mkdir -p $BUILD_BASE

cd $TFA_SRC_DIR

# TODO: also log writeups for all the other errors found in boot process with ACS tests, in hafnium and TF-A
# and the three-way mix between them and how they created device memory, dts mismatch, manifest mismatch, 
# and "Invalid device memory region\|device memory region range" in hafnium/src/manifest.c because of 
# TF-A's fallback dts spmc manifest being passed to ACS SPs, etc

# TODO: log a writeup for the uart0-2.log where we build hafnium for SP to run at EL0 but was providing ACS
# manifest that had dts for SP at EL1, and that was leading to a page fault as logged in uart0-2.log

# NOTE: using ARM_SPMC_MANIFEST_DTS as fvp_spmc_manifest.dts resulted in error logged in uart0-3.log
# it was giving 8 vcpus for SP running at EL0 which is not allowed, (as per hafnium source code src/load.c:732
# rule being *An S-EL0 partition must contain only 1 vCPU (UP migratable) per the FF-A 1.0 spec.* )
# changed it to fvp_spmc_manifest_el0.dts and as logged in uart0-4.log, that error disappeared
make -j"$JOBS" \
	PLAT=$PLAT ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE \
	LOG_LEVEL=50 BUILD_TYPE=$BUILD_TYPE BUILD_BASE=$BUILD_BASE \
	SPD=spmd BRANCH_PROTECTION=1 ARM_ARCH_MINOR=5 ENABLE_FEAT_MTE2=1 \
	GIC_EXT_INTID=1 CTX_INCLUDE_EL2_REGS=1 CTX_INCLUDE_PAUTH_REGS=1 \
	SPMD_SPM_AT_SEL2=1 \
	BL32="$BL32" \
	BL33="$BL33" \
	SP_LAYOUT_FILE="$SP_LAYOUT" \
	ARM_BL2_SP_LIST_DTS="$BUILD_BASE/$PLAT/$BUILD_TYPE/sp_list_fragment.dts" \
	ARM_SPMC_MANIFEST_DTS="$ROOT/ff-a-acs/platform/manifest/tgt_tfa_fvp/fvp_spmc_manifest_el0.dts" \
	all fip
