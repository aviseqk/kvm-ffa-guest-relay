#!/usr/bin/env bash

set -euo pipefail

BUILD_TYPE="$1"

case "$BUILD_TYPE" in
	kvm-host|kvm-guest)
		;;
	*)
		echo "Usage: $0 <kvm-host|kvm-guest> " >&2
		exit 1
		;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

JOBS="${JOBS:-$(nproc)}"

BR_SOURCE="$ROOT/buildroot"
OUTPUT_ROOT="$ROOT/out/buildroot"
OUTPUT_DIR="$OUTPUT_ROOT/$BUILD_TYPE"

DEFCONFIG="$ROOT/configs/buildroot/linux_br_${BUILD_TYPE#*-}_defconfig"

echo "Using Buildroot defconfig:"
echo "  $DEFCONFIG"

mkdir -p "$OUTPUT_DIR"

echo "Using $JOBS parallel job(s)"

cd "$BR_SOURCE"

#     BR2_EXTERNAL="$ROOT/br-ext" \
make \
    O="$OUTPUT_DIR" \
    BR2_DEFCONFIG="$DEFCONFIG" \
    defconfig

make -j"$JOBS" \
    O="$OUTPUT_DIR"
