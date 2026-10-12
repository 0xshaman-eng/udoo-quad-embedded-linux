# 03 - Linux Kernel and Device Tree

**Goal:** build Linux 6.6.21 (LTS) and the UDOO Quad device tree.

---

## Theory

| Output | What it is |
|---|---|
| `zImage` | Self-decompressing compressed kernel for 32-bit ARM |
| `imx6q-udoo.dtb` | Compiled device tree: describes CPU, memory, UARTs, Ethernet, SD... |

The kernel is **generic**; the **device tree** makes it fit a specific board.
`imx_v6_v7_defconfig` builds one kernel for many i.MX6/7 boards, and the dtb selects the board.

### zImage vs uImage

| | `uImage` | `zImage` |
|---|---|---|
| Format | zImage + 64-byte U-Boot legacy header | Raw self-decompressing kernel |
| U-Boot command | `bootm` | `bootz` |
| Needs | `mkimage`, `LOADADDR=` | Nothing extra |
| Used by | Older courses / old U-Boot | **This project** |

---

## Steps

```bash
./scripts/build-kernel.sh
```

Manual equivalent:

```bash
cd ~/Udoo_Workspace
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.21.tar.xz
tar xf linux-6.6.21.tar.xz && cd linux-6.6.21
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- imx_v6_v7_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc) zImage dtbs modules
```

Outputs:

```
arch/arm/boot/zImage
arch/arm/boot/dts/nxp/imx/imx6q-udoo.dtb      # kernel 6.5+
arch/arm/boot/dts/imx6q-udoo.dtb              # kernel < 6.5
```

### Install the kernel modules into the root filesystem

Some drivers are built as **modules** (`.ko` files) instead of into `zImage`, for example
`g_ether` (USB Ethernet gadget, used in [07-usb-gadget-network](07-usb-gadget-network.md)).
They must be installed into the board's root filesystem:

```bash
sudo make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- \
    INSTALL_MOD_PATH=/srv/nfs/udoo modules_install
ls /srv/nfs/udoo/lib/modules/6.6.21/modules.dep
```

`scripts/setup-nfs-rootfs.sh` does this automatically.

| Created | Purpose |
|---|---|
| `lib/modules/6.6.21/kernel/...` | The `.ko` module files |
| `lib/modules/6.6.21/modules.dep` | Index of modules and their dependencies |

`modprobe` uses `modules.dep` to find a module **and load its dependencies first**
(`g_ether` needs `libcomposite`, `u_ether`, `usb_f_ecm`...). `insmod` loads one file and knows nothing
about dependencies - always install modules properly and use `modprobe`.

The folder name must match `uname -r` on the board exactly.

### Kernel options this project depends on

All are already enabled in `imx_v6_v7_defconfig`. Check with `make menuconfig` (search with `/`):

| Option | Why |
|---|---|
| `CONFIG_FEC` | i.MX6 Ethernet driver |
| `CONFIG_IP_PNP` | Kernel-level IP config (`ip=` boot argument) |
| `CONFIG_ROOT_NFS` | Root filesystem over NFS |
| `CONFIG_DEVTMPFS` | Automatic `/dev` device files |
| `CONFIG_SERIAL_IMX_CONSOLE` | Console on `ttymxc*` |
| `CONFIG_USB_ETH=m` | `g_ether` USB Ethernet gadget, built as a module |

### Save your config

```bash
./scripts/save-configs.sh       # runs make savedefconfig → configs/
```

---

## Verify

First test without a root filesystem (U-Boot prompt):

```
=> tftp 0x12000000 udoo/zImage
=> tftp 0x18000000 udoo/imx6q-udoo.dtb
=> setenv bootargs console=ttymxc1,115200
=> bootz 0x12000000 - 0x18000000
```

Expected end of log:

```
Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
```

This is **success** at this stage: kernel and dtb work; only the root filesystem is missing.

On the running system:

```
~ # uname -a
Linux udoo 6.6.21 #1 SMP ... armv7l GNU/Linux
~ # cat /proc/cpuinfo | grep -E "processor|CPU part"
```

Four processors with `CPU part : 0xc09` = ARM Cortex-A9 = i.MX6 **Quad**.

---

## UDOO vs BeagleBone

| | BeagleBone | UDOO Quad |
|---|---|---|
| defconfig | `omap2plus_defconfig` | `imx_v6_v7_defconfig` |
| Device tree | `am335x-boneblack.dtb` | `imx6q-udoo.dtb` |
| Console | `ttyS0` (old kernels: `ttyO0`) | `ttymxc1` |
| RAM start | `0x80000000` | `0x10000000` |
