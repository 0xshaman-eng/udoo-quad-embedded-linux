# BeagleBone Black vs UDOO Quad - Porting Cheat Sheet

This project follows a BeagleBone Black embedded Linux course on a **UDOO Quad**.
This table is the translation layer - and the *why* behind each difference.

| Item | BeagleBone Black | UDOO Quad | Why it differs |
|---|---|---|---|
| SoC | TI AM335x | NXP i.MX6Q | Different vendor |
| CPU | 1x Cortex-A8 | 4x Cortex-A9 | Both ARMv7, hard-float |
| RAM start | `0x80000000` | `0x10000000` | SoC memory map |
| Boot ROM reads | FAT file `MLO` | Raw sectors, IVT at 1 KiB | AM335x ROM understands FAT; i.MX6 ROM does not |
| First stage | `MLO` | `SPL` | Same thing, different name |
| SPL install | Copy to FAT | `dd ... seek=1` (1 KiB) | See above |
| U-Boot install | Copy `u-boot.img` to FAT | `dd ... seek=69` (69 KiB) | SPL raw-mode offset |
| U-Boot defconfig | `am335x_evm_defconfig` | `udoo_defconfig` | Board support |
| SD card in U-Boot | `mmc 0` | `mmc 2` | Controller numbering (uSDHC3) |
| `uEnv.txt` auto-load | Yes | No - set `bootcmd` once | Default environment differs |
| Kernel defconfig | `omap2plus_defconfig` | `imx_v6_v7_defconfig` | SoC family |
| Device tree | `am335x-boneblack.dtb` | `imx6q-udoo.dtb` | Board hardware |
| Serial console | `ttyS0` (old: `ttyO0`) | `ttymxc1` | UART driver naming |
| USB-serial | External USB-TTL cable | Onboard CP2104 (micro-USB) | Board design |
| Kernel boot command (this project) | `bootm` (uImage) in course | `bootz` (zImage) | Modern U-Boot boots zImage directly |
| Load addresses | `0x82000000` / `0x88000000` | `0x12000000` / `0x18000000` | RAM start differs |
| USB gadget port | Mini-USB (also powers the board) | Micro-USB **OTG** port (not the serial port) | Board design |
| USB Ethernet gadget | `g_ether` → `usb0` | `g_ether` → `usb0` (same) | Same Linux driver |
| Init scripts (rcS, rcK, S01logging, S02module, S40network) | Course versions | Same files + `# UDOO:` additions | NFS root needs `/var/run`, stale-state cleanup, `eth0` not `auto` |
| Toolchain | `arm-linux-gnueabihf-` | `arm-linux-gnueabihf-` | Same architecture |
| BusyBox rootfs | ✅ | ✅ same binaries | Rootfs depends on architecture, not board |
| Extra MCU | - | Atmel SAM3X (Arduino Due) | Real-time co-processor on the UDOO |

## The general rule

- **Board-specific:** bootloader install method, U-Boot config, kernel config, device tree, console name, addresses.
- **Architecture-specific (shared):** toolchain, BusyBox, root filesystem, applications.
