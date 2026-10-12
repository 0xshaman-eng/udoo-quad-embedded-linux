#!/bin/bash
# Save the U-Boot, kernel and BusyBox configurations from the source trees into configs/.
set -euo pipefail
source "$(dirname "$0")/config.sh"

mkdir -p "$REPO_ROOT/configs"

save_defconfig() {
    local name="$1" dir="$2" dest="$3"
    if [ ! -f "$dir/.config" ]; then
        info "Skipping $name: no .config in $dir"
        return
    fi
    info "Saving $name config"
    make -C "$dir" savedefconfig >/dev/null
    cp "$dir/defconfig" "$dest"
    ok "$dest ($(wc -l < "$dest") lines)"
}

save_defconfig "U-Boot" "$UBOOT_DIR"  "$SAVED_UBOOT_CONFIG"
save_defconfig "Linux"  "$KERNEL_DIR" "$SAVED_KERNEL_CONFIG"

# BusyBox has no savedefconfig - save the full .config
if [ -f "$BUSYBOX_DIR/.config" ]; then
    cp "$BUSYBOX_DIR/.config" "$SAVED_BUSYBOX_CONFIG"
    ok "$SAVED_BUSYBOX_CONFIG"
else
    info "Skipping BusyBox: no .config in $BUSYBOX_DIR"
fi

echo
echo "Review and commit:"
echo "  git add configs/ && git commit -m \"configs: save U-Boot, kernel and BusyBox configs\""
