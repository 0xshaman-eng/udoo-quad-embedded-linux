#!/bin/bash
# Partition an SD card and write SPL + u-boot.img for the UDOO Quad.
#
# Usage:  ./scripts/flash-sd.sh /dev/sdX            # full setup (ERASES the card)
#         ./scripts/flash-sd.sh /dev/sdX --uboot-only  # only rewrite the bootloader
#
# Layout:
#   0 - 4 MiB      raw area: SPL at 1 KiB, u-boot.img at 69 KiB
#   partition 1    FAT32, 200 MiB, label BOOT   (uEnv.txt)
#   partition 2    ext4, rest of card, label ROOTFS
set -euo pipefail
source "$(dirname "$0")/config.sh"

DEV="${1:-}"
MODE="${2:-full}"
[ -n "$DEV" ] || die "Usage: $0 /dev/sdX [--uboot-only]"
[ -b "$DEV" ] || die "$DEV is not a block device"

# ---------- Safety checks ----------
TYPE=$(lsblk -dno TYPE "$DEV")
[ "$TYPE" = "disk" ] || die "$DEV is a $TYPE. Give the whole disk (e.g. /dev/sda), not a partition."

RM=$(lsblk -dno RM "$DEV" | tr -d ' ')
TRAN=$(lsblk -dno TRAN "$DEV" | tr -d ' ')
NAME=$(basename "$DEV")
if [ "$RM" != "1" ] && [ "$TRAN" != "usb" ] && [[ "$NAME" != mmcblk* ]]; then
    die "$DEV does not look like a removable SD card (RM=$RM, TRAN=$TRAN). Refusing."
fi

SIZE_GB=$(( $(lsblk -dbno SIZE "$DEV") / 1024 / 1024 / 1024 ))
[ "$SIZE_GB" -le 128 ] || die "$DEV is ${SIZE_GB} GB - too big for an SD card. Refusing."

if lsblk -no MOUNTPOINT "$DEV" | grep -qE '^/$|^/boot'; then
    die "$DEV holds a system mount point. Refusing."
fi

[ -f "$UBOOT_DIR/SPL" ] && [ -f "$UBOOT_DIR/u-boot.img" ] || \
    die "SPL / u-boot.img not found in $UBOOT_DIR. Run ./scripts/build-uboot.sh first."

# Partition names: /dev/sda -> /dev/sda1, /dev/mmcblk0 -> /dev/mmcblk0p1
if [[ "$NAME" =~ [0-9]$ ]]; then P="${DEV}p"; else P="$DEV"; fi

echo
lsblk "$DEV"
echo
if [ "$MODE" = "--uboot-only" ]; then
    echo "This will rewrite the bootloader on $DEV (partitions are kept)."
else
    echo "This will ERASE EVERYTHING on $DEV (${SIZE_GB} GB)."
fi
read -r -p "Type YES to continue: " answer
[ "$answer" = "YES" ] || die "Aborted."

info "Unmounting $DEV partitions"
for part in "${DEV}"?*; do sudo umount "$part" 2>/dev/null || true; done

if [ "$MODE" != "--uboot-only" ]; then
    info "Wiping the first 10 MiB"
    sudo dd if=/dev/zero of="$DEV" bs=1M count=10 conv=fsync status=none

    info "Creating partitions"
    sudo sfdisk "$DEV" << EOF
label: dos
start=8192, size=200M, type=c, bootable
start=417792, type=83
EOF
    sudo partprobe "$DEV" 2>/dev/null || true
    sleep 2

    info "Formatting partitions"
    sudo mkfs.vfat -F 32 -n BOOT "${P}1" >/dev/null
    sudo mkfs.ext4 -F -q -L ROOTFS "${P}2"
fi

info "Writing SPL (1 KiB) and u-boot.img (69 KiB)"
sudo dd if="$UBOOT_DIR/SPL"        of="$DEV" bs=1k seek=1  conv=fsync status=none
sudo dd if="$UBOOT_DIR/u-boot.img" of="$DEV" bs=1k seek=69 conv=fsync status=none

if [ "$MODE" != "--uboot-only" ]; then
    info "Copying boot/uEnv.txt to the BOOT partition"
    MNT=$(mktemp -d)
    sudo mount "${P}1" "$MNT"
    sudo cp "$REPO_ROOT/boot/uEnv.txt" "$MNT/"
    sudo umount "$MNT"
    rmdir "$MNT"
fi

sync
ok "SD card ready."
lsblk "$DEV"
echo
echo "First boot only - at the U-Boot prompt run:"
echo "  setenv bootcmd 'fatload mmc 2:1 0x11000000 uEnv.txt; env import -t 0x11000000 \${filesize}; run uenvcmd'"
echo "  saveenv"
