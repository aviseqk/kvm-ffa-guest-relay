#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

TFA_SRC_DIR=
# Build configuration - default using all available cores
JOBS="${JOBS:-$(nproc)}"
echo "Using $JOBS parallel job(s)"

BUILD_BASE="$ROOT/out/tf-a"
PLAT=fvp
ARCH=aarch64
CROSS_COMPILE=aarch64-none-linux-gnu-
BUILD_TYPE=debug

# UBoot artifacts
BL33="$ROOT/out/uboot/u-boot.bin"

if [[ ! -f "$BL33" ]]; then
	echo "ERROR: BL33 image not found!:"
	echo " $BL33"
	exit 1
fi

echo "SUCCESS: Found BL33 image:"
echo " $BL33"

mkdir -p $BUILD_BASE

cd "$ROOT/tf-a"

make -j"$JOBS" \
	PLAT=$PLAT \
	ARCH=$ARCH \
	LOG_LEVEL=40 \
	CROSS_COMPILE=$CROSS_COMPILE \
	BUILD_TYPE=$BUILD_TYPE \
	BUILD_BASE=$BUILD_BASE \
	BL33="$BL33" \
	fip fiptool
