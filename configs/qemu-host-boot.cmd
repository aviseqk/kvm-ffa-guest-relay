# Linux Host Boot Configuration for QEMU virt

setenv kernel_addr_r 0x40200000
setenv fdt_addr_r 0x40000000
setenv ramdisk_addr_r 0x48000000

setenv bootargs 'console=ttyAMA0,115200 rdinit=/sbin/init kgdbwait'

echo "Booting shared host Linux on QEMU virt..."
echo "Kernel:  ${kernel_addr_r}"
echo "FDT:     ${fdt_addr_r}"
echo "Initrd:  ${ramdisk_addr_r}"
echo "Initrd size: @INITRD_SIZE@"

booti ${kernel_addr_r} ${ramdisk_addr_r}:@INITRD_SIZE@ ${fdt_addr_r}

