#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

QEMU_BIN="$ROOT/out/qemu/build-11.1.2/qemu-system-aarch64"

QEMU="${QEMU_BIN:-qemu-system-aarch64}"
MEMORY="${MEMORY:-4096}"
CPUS="${CPUS:-4}"

# INFO: QEMU itself generates the virt machine DTB and passes it to Linux, no need to pass it like in Arm's FVP case
LINUX_HOST_IMAGE="$ROOT/out/linux/host/arch/arm64/boot/Image"
LINUX_HOST_INITRD="$ROOT/out/buildroot/kvm-host/images/rootfs.cpio.gz"

LINUX_HOST_INITRD_SIZE="$(stat -c '%s' "$LINUX_HOST_INITRD")"
LINUX_HOST_INITRD_SIZE_HEX="$(printf '0x%x' "$LINUX_HOST_INITRD_SIZE")"

TFA_BIOS="$ROOT/out/tf-a/qemu/debug/qemu_fw.bios"

BOOT_CMD_TEMPLATE="$ROOT/configs/qemu-host-boot.cmd"
BOOT_CMD_RUNTIME="$ROOT/out/qemu/uboot/host-boot-runtime.cmd"
BOOT_SCRIPT="$ROOT/out/qemu/uboot/host-boot.scr"
MKIMAGE="$ROOT/out/qemu/uboot/tools/mkimage"

KERNEL_ADDR=0x40200000
BOOT_SCRIPT_ADDR=0x47f00000
INITRD_ADDR=0x48000000

# Substitute the initramfs size into the text template.
sed "s/@INITRD_SIZE@/$LINUX_HOST_INITRD_SIZE_HEX/g" \
    "$BOOT_CMD_TEMPLATE" > "$BOOT_CMD_RUNTIME"

"$MKIMAGE" -A arm64 \
    -T script -C none \
    -n "QEMU Linux host boot configuration" \
    -d "$BOOT_CMD_RUNTIME" \
    "$BOOT_SCRIPT"

LOG_ROOT="$ROOT/devel-logs/qemu"
RUN_ID="$(date '+%Y-%m-%d_%H-%M-%S')"
LOG_DIR="$LOG_ROOT/$RUN_ID"
mkdir -p "$LOG_DIR"

for f in "$LINUX_HOST_IMAGE" "$LINUX_HOST_INITRD" "$TFA_BIOS" "$MKIMAGE" "$BOOT_CMD_TEMPLATE"; do
  [[ -f "$f" ]] || {
    echo "Required artifact not found: $f" >&2
    exit 1
  }
done

TFA_OUT_DIR=out/tf-a/qemu/debug

#-kernel "$LINUX_HOST_IMAGE"
#-initrd "$LINUX_HOST_INITRD"
#-append 'console=ttyAMA0,115200 rdinit=/sbin/init kvm-arm.mode=protected'

ARGS=(
	-machine virt,acpi=off,secure=on,virtualization=on,gic-version=3,mte=on
	-cpu max,sme=on,pauth-impdef=on
	-accel tcg
	-S
	-gdb tcp::1234
	-smp "$CPUS"
	-m "$MEMORY"
	-bios "$TFA_BIOS"
	-qmp unix:/tmp/qemu-monitor.sock,server=on,wait=off
	# Preload the kernel, initramfs, and legacy U-Boot script into RAM.
	-device "loader,file=$LINUX_HOST_IMAGE,addr=$KERNEL_ADDR,force-raw=on"
	-device "loader,file=$LINUX_HOST_INITRD,addr=$INITRD_ADDR,force-raw=on"
	-device "loader,file=$BOOT_SCRIPT,addr=$BOOT_SCRIPT_ADDR,force-raw=on"
	-nographic
	-d unimp,guest_errors,cpu_reset
	-D "$ROOT/out/qemu/qemu-debug.log"
	-semihosting-config enable=on,target=native
	)

"$QEMU" "${ARGS[@]}" 2>&1 | tee "$LOG_DIR/qemu.log"
