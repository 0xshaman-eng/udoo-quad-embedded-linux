#!/bin/bash
# Build U-Boot (SPL + u-boot.img) for the UDOO Quad.
set -euo pipefail
source "$(dirname "$0")/config.sh"
require_toolchain

fetch_source "$UBOOT_URL" "$UBOOT_DIR"
cd "$UBOOT_DIR"

if [ -f "$SAVED_UBOOT_CONFIG" ]; then
    info "Using saved config: $(basename "$SAVED_UBOOT_CONFIG")"
    cp "$SAVED_UBOOT_CONFIG" .config
    make olddefconfig
else
    info "Using upstream $UBOOT_DEFCONFIG"
    make "$UBOOT_DEFCONFIG"
fi

info "Building U-Boot with $JOBS jobs"
make -j"$JOBS"

[ -f SPL ] && [ -f u-boot.img ] || die "SPL or u-boot.img was not produced"

offset_hex=$(grep -oP '^CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=\K.*' .config || echo "0x8a")
offset_kib=$(( offset_hex * 512 / 1024 ))

ok "Build finished:"
ls -l SPL u-boot.img
echo
echo "Write to SD card:  ./scripts/flash-sd.sh /dev/sdX"
echo "  SPL        -> 1 KiB offset"
echo "  u-boot.img -> ${offset_kib} KiB offset (sector $offset_hex)"
