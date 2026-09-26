#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

KVMTOOL_SRC_DIR="$ROOT/tools/kvmtool"
echo "$KVMTOOL_SRC_DIR"

# Build configuration - default using all available cores
JOBS="${JOBS:-$(nproc)}"

OUTPUT_DIR="$ROOT/out/kvmtool"

ARCH=arm64
# NOTE: use Buildroot's generated toolchain for building kvmtool
CROSS_COMPILE="$ROOT/out/buildroot/host/bin/aarch64-buildroot-linux-gnu-"

mkdir -p "$OUTPUT_DIR"

echo "Using $JOBS parallel job(s)"

make -C "$KVMTOOL_SRC_DIR" \
    -j"$JOBS" \
    ARCH="$ARCH" \
    CROSS_COMPILE="$CROSS_COMPILE" \
    LIBFDT_DIR="$ROOT/out/buildroot/build/dtc-1.7.2/libfdt"

# Copy the lkvm binary to output folder and to buildroot rootfs-overlay
cp "$KVMTOOL_SRC_DIR/lkvm" "$OUTPUT_DIR"
