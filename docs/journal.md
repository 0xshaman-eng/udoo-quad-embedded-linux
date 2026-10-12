# Learning Journal

One entry per session: what I did, what broke, what I learned.

---

## 2026-10-10 - U-Boot, kernel, network boot

**Done**
- Built mainline U-Boot 2024.01 (`udoo_defconfig`) and Linux 6.6.21 (`imx_v6_v7_defconfig`).
- Learned the BeagleBone method (MLO + u-boot.img copied to FAT) does not work on i.MX6: the Boot ROM reads raw sectors.
- Partitioned the SD card (FAT at 4 MiB + ext4), wrote SPL at 1 KiB and u-boot.img at 69 KiB.
- Reached the U-Boot prompt over the onboard CP2104 serial port (`/dev/ttyUSB0`, 115200).
- Set up a direct Ethernet link (laptop `192.168.7.1`, board `192.168.7.2`) while keeping internet on the phone hotspot.
- Loaded `zImage` + `imx6q-udoo.dtb` over TFTP → kernel booted to the expected "Unable to mount root fs" panic.
- Exported `/srv/nfs/udoo` over NFS, reused my static BusyBox build, added `inittab` and `rcS` → BusyBox shell on the board.

**Broke / fixed**
- Used `/media/...` instead of `/dev/sda` for `sfdisk`.
- `sfdisk` placed partition 2 inside the U-Boot area - fixed with an explicit `start=`.
- apt locked by `unattended-upgr --download-only` - stopped the apt-daily services.
- TFTP "Permission denied" - folder missing the `x` bit (`namei -l` found it).
- `/tftpboot` held Zynq PetaLinux files - moved UDOO files to `/tftpboot/udoo/`.

**Learned**
- Why SPL exists: DDR is not usable at power-on; SPL runs in 256 KB OCRAM and initialises it.
- `zImage` + `bootz` replaces `uImage` + `bootm` on modern U-Boot.
- The rootfs depends on CPU architecture/ABI, not the board.
- NFS root on Ubuntu 24.04 needs `v3`.

---

## 2026-10-11 - Automatic boot with uEnv.txt

**Done**
- Wrote `uEnv.txt` with IPs, load addresses, `bootargs` and `uenvcmd`.
- Set `bootcmd` to `fatload` + `env import -t` + `run uenvcmd`, then `saveenv`.
- Board now boots fully automatically: SD → U-Boot → TFTP → NFS → shell.
- Organised everything into this repository.

**Broke / fixed**
- `ls mmc 0:1` → "Bad device specification". `mmc list` showed the SD card is `mmc 2`.

**Learned**
- U-Boot names devices per controller; the UDOO slot is on uSDHC3 → `mmc 2`.
- Single quotes in `setenv bootcmd '...'` delay `${filesize}` expansion until boot.

**Next**
- [ ] Capture a full boot log into `logs/network-boot.log`
- [ ] Run `scripts/save-configs.sh` and commit `configs/`
- [ ] Compare `RFS_Static` vs `RFS_Dynamic` (size, required libraries)
- [ ] Add `/etc/fstab`, `/etc/hostname`, `/etc/profile`
- [ ] Continue the course: device tree, Buildroot, GPIO, I2C

---

## 2026-10-11 - Init system and USB gadget networking

**Done**
- Replaced my simple startup script with the course's SysV-style init scripts: `rcS`, `rcK`, `S01logging`, `S02module`, `S40network`.
- Adapted them for the UDOO (marked `# UDOO:`): extra mounts and `/var/run` in `rcS`, fixed MACs for `g_ether`, NFS-safe `S40network`.
- Wrote `/etc/network/interfaces`: `lo` and `usb0` auto, `eth0` defined but not auto.
- Installed kernel modules with `modules_install` so `modprobe g_ether` works.
- Configured the laptop side of the USB link (`enx020000000601`, `192.168.6.1`).
- Everything starts at boot: syslogd/klogd, g_ether, usb0 - ping over USB works.

**Broke / fixed**
- `ifup` died on missing `/var/run` → `rcS` creates it.
- `File exists` on `lo` → flush before `ifup`.
- Stale `/var/run/ifstate` on the NFS root → removed at start.
- Random `g_ether` MACs changed the laptop interface name → fixed MACs.
- Ping failed until the laptop side had an IP.

**Learned**
- Boot chain: kernel → init → inittab → rcS → S?? scripts → interfaces.
- Separation of jobs: inittab (what), rcS/rcK (order), S scripts (how), interfaces (settings).
- `ifup -a` / `ifdown -a` only touch `auto` interfaces - this keeps the NFS root safe.
- `modprobe` needs `modules.dep`; it loads dependencies, `insmod` does not.

**Next**
- [ ] S50sshd with Dropbear (SSH over usb0)
- [ ] `/etc/passwd`, `/etc/shadow`, `/etc/group`
- [ ] Capture `logs/network-boot.log`, run `scripts/save-configs.sh`

---

## Template

```
## YYYY-MM-DD - Topic

**Done**
-

**Broke / fixed**
-

**Learned**
-

**Next**
- [ ]
```
