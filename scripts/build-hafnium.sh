#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

HAFNIUM_SRC_DIR="$ROOT/hafnium"

# Build configuration - default using all available cores
JOBS="${JOBS:-$(nproc)}"
echo "Using $JOBS parallel job(s)"

PLATFORM="${PLATFORM:-secure_aem_v8a_fvp_vhe}"

case "$PLATFORM" in
    secure_aem_v8a_fvp_vhe)
        OUTPUT_DIR="${OUTPUT_DIR:-$ROOT/out/hafnium/fvp}"
        ;;
    secure_qemu_aarch64)
        OUTPUT_DIR="${OUTPUT_DIR:-$ROOT/out/hafnium/qemu}"
        ;;
    *)
        OUTPUT_DIR="${OUTPUT_DIR:-$ROOT/out/hafnium/$PLATFORM}"
        echo "Unsupported PLATFORM='$PLATFORM' (in current lab); use fvp or qemu." >&2
    	exit 2

        ;;
esac

mkdir -p "$OUTPUT_DIR"

cd $HAFNIUM_SRC_DIR

echo $PLATFORM
make \
    LOG_LEVEL=40 \
    OUT="$OUTPUT_DIR" \
    PLATFORM="$PLATFORM"
