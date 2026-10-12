#!/bin/bash
# Build the Linux kernel (zImage), kernel modules and the UDOO device tree (imx6q-udoo.dtb).
set -euo pipefail
source "$(dirname "$0")/config.sh"
require_toolchain

fetch_source "$KERNEL_URL" "$KERNEL_DIR"
cd "$KERNEL_DIR"

if [ -f "$SAVED_KERNEL_CONFIG" ]; then
    info "Using saved config: $(basename "$SAVED_KERNEL_CONFIG")"
    cp "$SAVED_KERNEL_CONFIG" .config
    make olddefconfig
else
    info "Using upstream $KERNEL_DEFCONFIG"
    make "$KERNEL_DEFCONFIG"
fi

info "Building zImage, device trees and modules with $JOBS jobs"
make -j"$JOBS" zImage dtbs modules

DTB_PATH=$(find arch/arm/boot/dts -name "$DTB_NAME" | head -n1)
[ -f arch/arm/boot/zImage ] || die "zImage was not produced"
[ -n "$DTB_PATH" ]          || die "$DTB_NAME was not produced"

ok "Build finished:"
ls -l arch/arm/boot/zImage "$DTB_PATH"
echo
echo "Deploy kernel + dtb to TFTP:      ./scripts/deploy-tftp.sh"
echo "Install modules into NFS rootfs:  ./scripts/setup-nfs-rootfs.sh"
