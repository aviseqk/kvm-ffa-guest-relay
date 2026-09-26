#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Build configuration - default using all available cores
JOBS="${JOBS:-$(nproc)}"
echo "Using $JOBS parallel job(s)"

OUTPUT_DIR="$ROOT/out/uboot"

DEFCONFIG=vexpress_fvp_defconfig

ARCH="arm"
CROSS_COMPILE="aarch64-none-linux-gnu-"

mkdir -p "$OUTPUT_DIR"

make -C "$ROOT/u-boot" \
	-j"$JOBS" \
	O="$OUTPUT_DIR" \
	ARCH="$ARCH" \
	CROSS_COMPILE="$CROSS_COMPILE" \
	"$DEFCONFIG"


# adding config values to u-boot's own compile-time env-variables for boot-automation
"$ROOT/u-boot/scripts/config" --file "$OUTPUT_DIR/.config" --set-str BOOTCOMMAND 'booti ${kernel_addr_r} ${ramdisk_addr_r}:0x12e57ca ${fdt_addr_r}'
"$ROOT/u-boot/scripts/config" --file "$OUTPUT_DIR/.config" --set-val BOOTDELAY 0

#"$ROOT/u-boot/scripts/config" --file "$OUTPUT_DIR/.config" \
#	--enable USE_BOOTARGS

#"$ROOT/u-boot/scripts/config" --file "$OUTPUT_DIR/.config" \
#	--set-str BOOTARGS 'kvm-arm.mode=none'

# ramdisk_size is a env variable we created for our rootfs size, but instead of a precise size, assigning a fixed but big upper bound to it.
# TODO: figure out a way to provide this to U-Boot as env value "$ROOT/u-boot/scripts/config" --file "$OUTPUT_DIR/.config" --set-str EXTRA_ENV_SETTINGS 'ramdisk_size=0x400000'

#make -C "$ROOT/u-boot" \
#	-j"$JOBS" \
#	O="$OUTPUT_DIR" \
#	ARCH="$ARCH" \
#	CROSS_COMPILE="$CROSS_COMPILE" \
#	olddefconfig

make -C "$ROOT/u-boot" \
	-j"$JOBS" \
	O="$OUTPUT_DIR" \
	ARCH="$ARCH" \
	CROSS_COMPILE="$CROSS_COMPILE"
