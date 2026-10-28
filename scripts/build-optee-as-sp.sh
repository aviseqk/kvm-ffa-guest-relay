#!/usr/bin/env bash

set -euo pipefail

# build OP-TEE as an S-EL1 Secure Partition managed by Hafnium S-EL2 SPMC

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JOBS="${JOBS:-$(nproc)}"

OPTEE_OS_SRC="$ROOT/optee_os"

# output directory as referenced in the sp-layout.json
OPTEE_OUT="../out/optee"


PLATFORM="vexpress-qemu_armv8a"
ARCH="arm"
CROSS_COMPILE="${AARCH64_CROSS_COMPILE:-aarch64-none-linux-gnu-}"
BUILD_TYPE="debug"

if [[ ! -f "${OPTEE_OS_SRC}/core/arch/arm/plat-vexpress/conf.mk" ]]; then
	echo "ERROR: OPTEE OS source tree not found for ${PLAT}" >&2
	exit 1
fi

echo "OP-TEE source: ${OPTEE_OS_SRC}"
echo "Output:        ${OPTEE_OS_SRC}/${OPTEE_OUT}"

COMMON_ARGS=(
	-j"$JOBS"
	O="$OPTEE_OUT"
	PLATFORM="$PLATFORM"
	ARCH="$ARCH"
	CROSS_COMPILE64="$CROSS_COMPILE"
	CFG_ARM64_core=y
	CFG_ARM32_core=n
	CFG_USER_TA_TARGETS=ta_arm64
	CFG_CORE_SEL2_SPMC=y
	CFG_ARM_GICV3=n
	CFG_CORE_HAFNIUM_INTC=y
	CFG_CORE_WORKAROUND_NSITR_CACHE_PRIME=n
	CFG_TZDRAM_START=0x0e304000
	CFG_TZDRAM_SIZE=0x00cfc000
	DEBUG=1
	CFG_TEE_CORE_LOG_LEVEL=3
)

mkdir -p "$OPTEE_OUT"
cd "$OPTEE_OS_SRC"

make "${COMMON_ARGS[@]}" 

echo
echo "OP-TEE build finished"

if [[ ! -f "${OPTEE_OS_SRC}/${OPTEE_OUT}/core/tee-raw.bin" ]]; then
    echo "ERROR: Expected tee-raw.bin was not produced." >&2
    echo "Inspect the build output and actual generated artifacts." >&2
    exit 1
fi

echo "Verified: tee-raw.bin exists."
