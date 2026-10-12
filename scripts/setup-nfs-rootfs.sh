#!/bin/bash
# Export $NFS_ROOT over NFS and fill it with:
#   BusyBox + standard folders + rootfs/overlay (init scripts, network config) + kernel modules
set -euo pipefail
source "$(dirname "$0")/config.sh"

[ -f "$ROOTFS_DIR/bin/busybox" ] || die "BusyBox not found in $ROOTFS_DIR. Run ./scripts/build-busybox.sh first."
command -v exportfs >/dev/null || die "NFS server missing. Install it: sudo apt install nfs-kernel-server"

EXPORT_LINE="$NFS_ROOT $NFS_CLIENTS(rw,sync,no_root_squash,no_subtree_check)"

# ---------- NFS export ----------
info "Creating $NFS_ROOT"
sudo mkdir -p "$NFS_ROOT"
if ! grep -qsF "$NFS_ROOT " /etc/exports; then
    info "Adding export to /etc/exports"
    echo "$EXPORT_LINE" | sudo tee -a /etc/exports >/dev/null
else
    info "Export already present in /etc/exports"
fi
sudo exportfs -ra

# ---------- BusyBox ----------
info "Copying BusyBox from $ROOTFS_DIR"
sudo cp -a "$ROOTFS_DIR/." "$NFS_ROOT/"

# ---------- Standard folders ----------
info "Creating standard folders"
for d in dev proc sys tmp root run var/run var/log etc/init.d \
         etc/network/if-pre-up.d etc/network/if-up.d \
         etc/network/if-down.d etc/network/if-post-down.d; do
    sudo mkdir -p "$NFS_ROOT/$d"
done

# ---------- Overlay: inittab, init scripts, network config ----------
info "Copying rootfs overlay"
sudo cp -r "$REPO_ROOT/rootfs/overlay/." "$NFS_ROOT/"
sudo chmod +x "$NFS_ROOT"/etc/init.d/*

# ---------- Kernel modules (needed by S02module: g_ether) ----------
if [ -f "$KERNEL_DIR/arch/arm/boot/zImage" ]; then
    info "Installing kernel modules into $NFS_ROOT/lib/modules"
    sudo make -C "$KERNEL_DIR" ARCH="$ARCH" CROSS_COMPILE="$CROSS_COMPILE" \
        INSTALL_MOD_PATH="$NFS_ROOT" modules_install >/dev/null
    ls "$NFS_ROOT/lib/modules/"*/modules.dep >/dev/null || die "modules.dep was not created"
else
    info "Kernel not built yet - skipping modules (run ./scripts/build-kernel.sh, then this script again)"
fi

ok "NFS root filesystem ready:"
ls "$NFS_ROOT"
echo
ls -l "$NFS_ROOT/etc/init.d"
echo
sudo exportfs -v | grep -F "$NFS_ROOT" || die "Export not active"
