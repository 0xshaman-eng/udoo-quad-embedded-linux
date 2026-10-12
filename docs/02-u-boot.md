# 02 - U-Boot

**Goal:** build mainline U-Boot 2024.01 for the UDOO Quad, write it to an SD card and reach the `=>` prompt.

---

## Theory

U-Boot is built as **two images** (see [00-boot-process](00-boot-process.md)):

| File | Size | Role |
|---|---|---|
| `SPL` | ~43 KB | First stage. Contains the i.MX IVT header. Initialises DDR. |
| `u-boot.img` | ~400 KB | Full U-Boot with a header SPL uses to load it. |

> `u-boot.bin` is **not** used - it has no header, so SPL cannot load it.

`udoo_defconfig` covers both UDOO Dual and Quad; SPL detects the variant at runtime.

---

## Steps

### Build

```bash
./scripts/build-uboot.sh
```

Manual equivalent:

```bash
cd ~/Udoo_Workspace
wget https://ftp.denx.de/pub/u-boot/u-boot-2024.01.tar.bz2
tar xf u-boot-2024.01.tar.bz2 && cd u-boot-2024.01
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- udoo_defconfig
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j$(nproc)
```

### Prepare the SD card

```bash
lsblk                                  # find the card, e.g. /dev/sda (RM=1)
./scripts/flash-sd.sh /dev/sdX
```

Manual equivalent:

```bash
sudo umount /dev/sdX*
sudo dd if=/dev/zero of=/dev/sdX bs=1M count=10 conv=fsync

sudo sfdisk /dev/sdX << EOF
label: dos
start=8192, size=200M, type=c, bootable
start=417792, type=83
EOF

sudo mkfs.vfat -F 32 -n BOOT /dev/sdX1
sudo mkfs.ext4 -L ROOTFS /dev/sdX2

sudo dd if=SPL        of=/dev/sdX bs=1k seek=1  conv=fsync
sudo dd if=u-boot.img of=/dev/sdX bs=1k seek=69 conv=fsync
sync
```

| Value | Why |
|---|---|
| `start=8192` | Partition 1 at 4 MiB - leaves the raw area for U-Boot |
| `start=417792` | Partition 2 directly after partition 1 (must be given explicitly) |
| `seek=1` (KiB) | Boot ROM reads the IVT at 0x400 |
| `seek=69` (KiB) | `CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR=0x8a` → 138 × 512 B |

### Serial console

The micro-USB port is a CP2104 USB-UART bridge (`/dev/ttyUSB0`). Linux calls the port `ttymxc1`.

```bash
sudo picocom -b 115200 /dev/ttyUSB0      # exit: Ctrl+A, Ctrl+X
```

---

## Verify

Power on, press a key at the countdown:

```
U-Boot SPL 2024.01 ...
Trying to boot from MMC1

U-Boot 2024.01 ...
CPU:   Freescale i.MX6Q ...
Board: Udoo Quad
=>
```

---

## Useful U-Boot commands

| Command | Purpose |
|---|---|
| `version` | U-Boot version |
| `bdinfo` | Board info, RAM start and size |
| `mmc list` | List SD/MMC devices - **UDOO SD card is `mmc 2`** |
| `ls mmc 2:1` | List files on device 2, partition 1 (FAT) |
| `fatload mmc 2:1 <addr> <file>` | Load a file from FAT into RAM |
| `printenv` / `printenv bootcmd` | Show environment variables |
| `setenv <var> <value>` | Set a variable (until reset) |
| `saveenv` | Save the environment to the SD card |
| `env default -a` | Reset the environment to defaults (then `saveenv`) |
| `ping <ip>` / `tftp <addr> <file>` | Network test / download |
| `md <addr>` | Memory dump |

### Device naming: laptop vs U-Boot

| | Laptop | U-Boot |
|---|---|---|
| Whole SD card | `/dev/sda` | `mmc 2` |
| FAT partition | `/dev/sda1` | `mmc 2:1` |
| ext4 partition | `/dev/sda2` | `mmc 2:2` |

The i.MX6 has four SD controllers (uSDHC1-4). The UDOO's slot is on a later one, so U-Boot numbers it 2.

---

## UDOO vs BeagleBone

| | BeagleBone | UDOO Quad |
|---|---|---|
| First stage | `MLO` file on FAT | `SPL` raw at 1 KiB |
| U-Boot | `u-boot.img` file on FAT | `u-boot.img` raw at 69 KiB |
| defconfig | `am335x_evm_defconfig` | `udoo_defconfig` |
| SD in U-Boot | `mmc 0` | `mmc 2` |

---

## Problems I hit

- Used the mount folder instead of the device → [troubleshooting](troubleshooting.md#sfdisk-cannot-open-media-is-a-directory)
- Partition 2 created in the gap before partition 1 → [troubleshooting](troubleshooting.md#partition-2-created-before-partition-1)
- `Bad device specification mmc 0` → [troubleshooting](troubleshooting.md#u-boot-bad-device-specification-mmc-0)
