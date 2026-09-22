#!/usr/bin/env bash

#  This script is for the Non Secure with Host Linux boot test, where we validate the secure world software stack exists with the 
#  actual non-secure kernel booting properly with host Linux as KVM hypervisor in a way that 
#  where we still have SPMC at EL2 as Hafnium, and Arm FF-A ACS SP are created and their tests are performed, just that vm1.bin is no longer the NS kernel

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

FVP="FVP_Base_RevC-2xAEMvA"

BL1="$ROOT/out/tf-a/fvp/debug/bl1.bin" 
FIP="$ROOT/out/tf-a/fvp/debug/fip.bin" 


LINUX_HOST_IMAGE="$ROOT/out/linux/host/arch/arm64/boot/Image"
LINUX_HOST_DTB="$ROOT/out/linux/host/arch/arm64/boot/dts/arm/fvp-base-revc.dtb"
LINUX_HOST_INITRD="$ROOT/out/buildroot/images/rootfs.cpio.gz"

# U-Boot recommended addresses(as per linux's fvp-base-revc.dtb) : kernel_addr_r=0x80080000 fdt_addr_r=0x8fc00000 ramdisk_addr_r=0x8fe00000
FVP_LINUX_HOST_BOOT_CONFIG=(
    --data cluster0.cpu0="$LINUX_HOST_IMAGE@0x80080000"
    --data cluster0.cpu0="$LINUX_HOST_DTB@0x8fc00000"
    --data cluster0.cpu0="$LINUX_HOST_INITRD@0x8fe00000"
)

LOG_ROOT="$ROOT/devel-logs/fvp"
RUN_ID="$(date '+%Y-%m-%d_%H-%M-%S')"
LOG_DIR="$LOG_ROOT/$RUN_ID"

mkdir -p $LOG_DIR

# Each UART gets its own Kitty terminal. Telnet connects to the FVP terminal server.
FVP_TERMINAL_CONFIG=(
    -C 'bp.terminal_0.terminal_command=kitty --title "%title" telnet localhost %port'
    -C 'bp.terminal_1.terminal_command=kitty --title "%title" telnet localhost %port'
    -C 'bp.terminal_2.terminal_command=kitty --title "%title" telnet localhost %port'
    -C 'bp.terminal_3.terminal_command=kitty --title "%title" telnet localhost %port'
)

"$FVP" \
	-C pctl.startup=0.0.0.0 \
	-C bp.secure_memory=1 \
	-C cluster0.NUM_CORES=4 -C cluster1.NUM_CORES=4 \
	-C cluster0.has_arm_v8-5=1 -C cluster1.has_arm_v8-5=1 \
	-C cluster0.has_pointer_authentication=2 -C cluster1.has_pointer_authentication=2 \
	-C cluster0.memory_tagging_support_level=2 -C cluster1.memory_tagging_support_level=2 \
	-C cluster0.bti_support_level=1 -C cluster1.bti_support_level=1 \
	-C cluster0.has_branch_target_exception=1 -C cluster1.has_branch_target_exception=1 \
	-C bp.dram_metadata.is_enabled=1 \
	-C pci.pci_smmuv3.mmu.SMMU_AIDR=2 -C pci.pci_smmuv3.mmu.SMMU_IDR0=0x0046123B \
	-C pci.pci_smmuv3.mmu.SMMU_IDR1=0x00600002 -C pci.pci_smmuv3.mmu.SMMU_IDR3=0x1714 \
	-C pci.pci_smmuv3.mmu.SMMU_IDR5=0xFFFF0472 -C pci.pci_smmuv3.mmu.SMMU_S_IDR1=0xA0000002 \
	-C pci.pci_smmuv3.mmu.SMMU_S_IDR2=0 -C pci.pci_smmuv3.mmu.SMMU_S_IDR3=0 \
	-C bp.ve_sysregs.mmbSiteDefault=0 -C bp.ve_sysregs.exit_on_shutdown=1 \
	-C bp.pl011_uart0.untimed_fifos=1 -C bp.pl011_uart0.unbuffered_output=1 \
	-C bp.pl011_uart0.out_file="$LOG_DIR/uart0.log" \
	-C bp.pl011_uart1.untimed_fifos=1 -C bp.pl011_uart1.unbuffered_output=1 \
	-C bp.pl011_uart1.out_file="$LOG_DIR/uart1.log" \
	-C bp.pl011_uart2.untimed_fifos=1 -C bp.pl011_uart2.unbuffered_output=1 \
	-C bp.pl011_uart2.out_file="$LOG_DIR/uart2.log" \
	-C bp.secureflashloader.fname="$BL1" \
	-C bp.flashloader0.fname="$FIP" \
	-C cluster0.gicv3.extended-interrupt-range-support=1 -C cluster1.gicv3.extended-interrupt-range-support=1 \
	-C gic_distributor.extended-ppi-count=64 -C gic_distributor.extended-spi-count=1024 -C gic_distributor.ARE-fixed-to-one=1 \
	"${FVP_TERMINAL_CONFIG[@]}" \
	"${FVP_LINUX_HOST_BOOT_CONFIG[@]}"
