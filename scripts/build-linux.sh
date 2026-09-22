#!/usr/bin/env bash

set -euo pipefail

BUILD_TYPE="$1"

case "$BUILD_TYPE" in
	host|guest)
		;;
	*)
		echo "Usage: $0 <host|guest> " >&2
		exit 1
		;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

JOBS="${JOBS:-$(nproc)}"

LINUX_SRC="$ROOT/linux"
OUT_ROOT="$ROOT/out/linux"
OUT_DIR="$OUT_ROOT/$BUILD_TYPE"

FRAGMENT="$ROOT/configs/linux/linux-$BUILD_TYPE.fragment"

FVP_DTB="arm/fvp-base-revc.dtb"

LINUX_TARGETS=(Image)
LINUX_TARGETS+=(scripts_gdb)
LINUX_TARGETS+=("$FVP_DTB")

ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

mkdir -p "$OUT_DIR"

echo "Using $JOBS parallel job(s)"

# navigate to linux source directory and merge our fragment with the arch base defconfig to create final .config
cd "$LINUX_SRC"

ARCH="$ARCH" \
CROSS_COMPILE="$CROSS_COMPILE" \
scripts/kconfig/merge_config.sh \
    -O "$OUT_DIR" \
    arch/arm64/configs/defconfig \
    "$FRAGMENT"


# build the linux Image artifact
make -j"$JOBS" \
	-C "$LINUX_SRC" \
	O="$OUT_DIR" \
	ARCH="$ARCH" \
	CROSS_COMPILE="$CROSS_COMPILE" \
	"${LINUX_TARGETS[@]}"
