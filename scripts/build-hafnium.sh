#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

HAFNIUM_SRC_DIR="$ROOT/hafnium"

# Build configuration - default using all available cores
JOBS="${JOBS:-$(nproc)}"
echo "Using $JOBS parallel job(s)"

OUTPUT_DIR="$ROOT/out/hafnium"

mkdir -p "$OUTPUT_DIR"

cd $HAFNIUM_SRC_DIR

make \
    OUT="$OUTPUT_DIR" \
    PLATFORM=secure_aem_v8a_fvp_vhe
