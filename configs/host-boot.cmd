# Linux Host Boot Configuration

setenv bootargs 'console=ttyAMA0,115200 root=/dev/ram0 rw kgdbwait kgdboc=ttyAMA3,115200 kvm-arm.mode=protected'

setenv kernel_addr_r 0x80080000
setenv fdt_addr_r 0x8fc00000
setenv ramdisk_addr_r 0x8fe00000

# ramdisk_size is supplied by the FVP launcher and it is the actual initramfs file size in bytes.
booti ${kernel_addr_r} ${ramdisk_addr_r}:@INITRD_SIZE@ ${fdt_addr_r}
