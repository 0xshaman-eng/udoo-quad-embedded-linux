#!/bin/bash
# Shared settings for all scripts. Override any value from the environment, e.g.
#   WORKSPACE=~/work ./scripts/build-kernel.sh

# Versions
UBOOT_VERSION="${UBOOT_VERSION:-2024.01}"
KERNEL_VERSION="${KERNEL_VERSION:-6.6.21}"
BUSYBOX_VERSION="${BUSYBOX_VERSION:-1.38.0}"

# Toolchain
export ARCH=arm
export CROSS_COMPILE="${CROSS_COMPILE:-arm-linux-gnueabihf-}"
JOBS="${JOBS:-$(nproc)}"

# Folders
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="${WORKSPACE:-$HOME/Udoo_Workspace}"
UBOOT_DIR="$WORKSPACE/u-boot-$UBOOT_VERSION"
KERNEL_DIR="$WORKSPACE/linux-$KERNEL_VERSION"
BUSYBOX_DIR="$WORKSPACE/busybox-$BUSYBOX_VERSION"
ROOTFS_DIR="${ROOTFS_DIR:-$WORKSPACE/RFS_Static}"

# Board files
UBOOT_DEFCONFIG="udoo_defconfig"
KERNEL_DEFCONFIG="imx_v6_v7_defconfig"
DTB_NAME="imx6q-udoo.dtb"

# Saved configs in this repo (used automatically if present)
SAVED_UBOOT_CONFIG="$REPO_ROOT/configs/u-boot-${UBOOT_VERSION}_udoo_defconfig"
SAVED_KERNEL_CONFIG="$REPO_ROOT/configs/linux-${KERNEL_VERSION}_udoo_defconfig"
SAVED_BUSYBOX_CONFIG="$REPO_ROOT/configs/busybox-${BUSYBOX_VERSION}.config"

# Host servers
TFTP_DIR="${TFTP_DIR:-/tftpboot/udoo}"
NFS_ROOT="${NFS_ROOT:-/srv/nfs/udoo}"
NFS_CLIENTS="${NFS_CLIENTS:-192.168.7.0/24}"

# Download links
UBOOT_URL="https://ftp.denx.de/pub/u-boot/u-boot-${UBOOT_VERSION}.tar.bz2"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_VERSION%%.*}.x/linux-${KERNEL_VERSION}.tar.xz"
BUSYBOX_URL="https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2"

# Helpers
info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
ok()    { echo -e "\033[1;32m[ OK ]\033[0m $*"; }
die()   { echo -e "\033[1;31m[FAIL]\033[0m $*" >&2; exit 1; }

# Download and extract a source archive into $WORKSPACE if not already there
fetch_source() {
    local url="$1" dir="$2"
    local archive="$WORKSPACE/$(basename "$url")"
    mkdir -p "$WORKSPACE"
    if [ -d "$dir" ]; then
        info "Using existing source: $dir"
        return
    fi
    [ -f "$archive" ] || { info "Downloading $url"; wget -q --show-progress -O "$archive" "$url"; }
    info "Extracting $(basename "$archive")"
    tar xf "$archive" -C "$WORKSPACE"
}

require_toolchain() {
    command -v "${CROSS_COMPILE}gcc" >/dev/null || \
        die "${CROSS_COMPILE}gcc not found. Install it: sudo apt install gcc-arm-linux-gnueabihf"
}
