#!/bin/bash
# Build a static BusyBox and install it into $ROOTFS_DIR.
set -euo pipefail
source "$(dirname "$0")/config.sh"
require_toolchain

fetch_source "$BUSYBOX_URL" "$BUSYBOX_DIR"
cd "$BUSYBOX_DIR"

if [ -f "$SAVED_BUSYBOX_CONFIG" ]; then
    info "Using saved config: $(basename "$SAVED_BUSYBOX_CONFIG")"
    cp "$SAVED_BUSYBOX_CONFIG" .config
    yes "" | make oldconfig >/dev/null
else
    info "Using BusyBox defconfig + static build"
    make defconfig
    # Static binary: no shared libraries needed in the rootfs
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
    # 'tc' fails to build against Ubuntu 24.04 kernel headers (CBQ removed)
    sed -i 's/CONFIG_TC=y/# CONFIG_TC is not set/' .config
fi

info "Building BusyBox with $JOBS jobs"
make -j"$JOBS"

info "Installing into $ROOTFS_DIR"
make CONFIG_PREFIX="$ROOTFS_DIR" install

ok "BusyBox installed:"
file "$ROOTFS_DIR/bin/busybox"
echo
echo "Set up the NFS root filesystem:  ./scripts/setup-nfs-rootfs.sh"
