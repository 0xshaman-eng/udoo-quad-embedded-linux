#!/bin/bash
# Copy zImage and the device tree to the TFTP folder with readable permissions.
set -euo pipefail
source "$(dirname "$0")/config.sh"

ZIMAGE="$KERNEL_DIR/arch/arm/boot/zImage"
DTB=$(find "$KERNEL_DIR/arch/arm/boot/dts" -name "$DTB_NAME" 2>/dev/null | head -n1)

[ -f "$ZIMAGE" ] || die "zImage not found. Run ./scripts/build-kernel.sh first."
[ -n "$DTB" ]    || die "$DTB_NAME not found. Run ./scripts/build-kernel.sh first."

info "Copying to $TFTP_DIR"
sudo mkdir -p "$TFTP_DIR"
sudo cp "$ZIMAGE" "$DTB" "$TFTP_DIR/"

# The TFTP server runs as user 'tftp': folders need r-x, files need r--
sudo chmod 755 "$(dirname "$TFTP_DIR")" "$TFTP_DIR"
sudo chmod 644 "$TFTP_DIR"/*

ok "Deployed:"
ls -l "$TFTP_DIR"
echo
namei -l "$TFTP_DIR/zImage"
echo
echo "Reset the board to boot the new kernel."
