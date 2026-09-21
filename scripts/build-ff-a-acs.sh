#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

CROSS_COMPILE="aarch64-none-elf-"
ACS_SRC_DIR="$ROOT/ff-a-acs"

# Build configuration - default using all available cores
JOBS="${JOBS:-$(nproc)}"
echo "Using $JOBS parallel job(s)"

TARGET_NAME="tgt_tfa_fvp"
OUTPUT_DIR="$ROOT/out/ff-a-acs"

mkdir -p "$OUTPUT_DIR"

cd $ACS_SRC_DIR

# NOTE: DPLATFORM_NS_HYPERVISOR_PRESENT=0 is to put arm TFTF as non secure hypervisor, only for secure stack staging test, 
# but ACS docs also suggests its created vm1.bin can act as NS OS kernel for testing, so we might not need TFTF as BL33 separately.

cmake \
    -S "$ACS_SRC_DIR" \
    -B "$OUTPUT_DIR" \
    -DCROSS_COMPILE="$CROSS_COMPILE" \
    -DPLATFORM_SP_EL=0 \
    -DPLATFORM_NS_HYPERVISOR_PRESENT=0 \
    -DPLATFORM_FFA_V_ALL=1 \
    -DTARGET="$TARGET_NAME" \
    -DENABLE_BTI=ON

cmake \
    --build "$OUTPUT_DIR" \
    --parallel "$JOBS"

