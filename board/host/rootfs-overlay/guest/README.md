## Guest Kernel Boot Artifacts

I have placed the guest kernel image and rootfs artifacts in this directory.

These files are copied into and packaged in the host rootfs and used by `lkvm` to boot the linux guest under KVM.

Artifacts:
- `Image`           - guest Linux kernel ARM64 boot executable Image
- `rootfs.cpio.gz`  - guest Linux root filesystem

*These artifacts are not tracked by git, hence this intentional note for recallability*
