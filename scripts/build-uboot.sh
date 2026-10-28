#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Build configuration - default using all available cores
JOBS="${JOBS:-$(nproc)}"
echo "Using $JOBS parallel job(s)"

PLATFORM="${PLATFORM:-fvp}"
ARCH="arm"
CROSS_COMPILE="aarch64-none-linux-gnu-"

case "$PLATFORM" in
	fvp)
		OUTPUT_DIR="$ROOT/out/uboot/fvp"
		DEFCONFIG="vexpress_fvp_defconfig"
		;;
	qemu)
		OUTPUT_DIR="$ROOT/out/uboot/qemu"
		DEFCONFIG="qemu_arm64_defconfig"
		;;
	*)
		echo "Unsupported Platform: expected fvp or qemu" >&2
		exit 2
		;;
esac

mkdir -p "$OUTPUT_DIR"

echo "U-Boot build: platform=$PLATFORM defconfig=$DEFCONFIG output=$OUTPUT_DIR"

make -C "$ROOT/u-boot" \
	-j"$JOBS" \
	O="$OUTPUT_DIR" \
	ARCH="$ARCH" \
	CROSS_COMPILE="$CROSS_COMPILE" \
	"$DEFCONFIG"

# adding config values to u-boot's own compile-time env-variables for boot-automation
if [[ "$PLATFORM" == fvp ]]; then
	"$ROOT/u-boot/scripts/config" --file "$OUTPUT_DIR/.config" \
		--set-str BOOTCOMMAND 'source 0x8f000000'
else
	"$ROOT/u-boot/scripts/config" --file "$OUTPUT_DIR/.config" \
		--set-str BOOTCOMMAND 'source 0x47f00000'
fi

"$ROOT/u-boot/scripts/config" --file "$OUTPUT_DIR/.config" \
		--set-val BOOTDELAY 3

make -C "$ROOT/u-boot" \
	-j"$JOBS" \
	O="$OUTPUT_DIR" \
	ARCH="$ARCH" \
	CROSS_COMPILE="$CROSS_COMPILE"
