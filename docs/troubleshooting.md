# Troubleshooting

Real problems hit while building this project, with the cause and the fix.
Each entry: **Symptom → Cause → Fix → Lesson**.

---

## Host and SD card

### sfdisk cannot open /media: Is a directory

```
sfdisk: cannot open /media/shaman/3412-3037: Is a directory
```

- **Cause:** used the folder where the card is *mounted* instead of the *device*.
- **Fix:** find the device with `lsblk` (e.g. `sda`, `RM=1`) and use `/dev/sda`.
- **Lesson:** `/media/...` is a filesystem view; `sfdisk` and `dd` work on raw block devices in `/dev`.

### Partition 2 created before partition 1

```
/dev/sda1  *     8192 417791  409600  200M  c W95 FAT32 (LBA)
/dev/sda2        2048   8191    6144    3M 83 Linux
Partition table entries are not in disk order.
```

- **Cause:** the `sfdisk` script gave partition 2 no `start=`, so it filled the first free gap - inside the U-Boot raw area.
- **Fix:** give every partition an explicit start: `start=417792, type=83`. Nothing had been formatted, so re-running `sfdisk` was enough.
- **Lesson:** always read the "New situation" table before formatting.

### apt is locked by unattended-upgr

```
Waiting for cache lock: Could not get lock /var/lib/dpkg/lock-frontend.
It is held by process 606737 (unattended-upgr)
```

- **Cause:** Ubuntu's automatic updater was running.
- **Check:** `ps aux | grep unattended-upgr`. It showed `--download-only`, so nothing was being installed.
- **Fix:**
  ```bash
  sudo systemctl stop apt-daily.service apt-daily-upgrade.service
  ```
  If it is *installing*, wait. **Never delete lock files.** Repair a broken install with `sudo dpkg --configure -a`.
- **Lesson:** check what holds a lock before killing it.

---

## U-Boot

### Nothing on the serial console

- **Check:** `sudo dmesg | tail` shows `cp210x converter now attached to ttyUSB0`.
- **Check:** `dd` wrote to the whole disk (`/dev/sdX`, not `/dev/sdX1`) at `seek=1` and `seek=69`.
- **Lesson:** no output at all usually means SPL was never found by the Boot ROM.

### SPL starts but U-Boot does not

- **Cause:** `u-boot.img` missing or at the wrong offset (or `u-boot.bin` written instead).
- **Fix:** `sudo dd if=u-boot.img of=/dev/sdX bs=1k seek=69 conv=fsync`
- **Check offset:** `grep CONFIG_SYS_MMCSD_RAW_MODE_U_BOOT_SECTOR .config` → `0x8a` = 69 KiB.

### U-Boot: Bad device specification mmc 0

```
=> ls mmc 0:1
** Bad device specification mmc 0 **
```

- **Cause:** U-Boot numbers SD devices by controller. The UDOO slot is on uSDHC3.
- **Fix:** `mmc list` → `FSL_SDHC: 2 (SD)`. Use `mmc 2:1`.
- **Lesson:** never assume device numbers from another board's tutorial (BeagleBone uses `mmc 0`).

### U-Boot: ethaddr not set

- **Fix:** `setenv ethaddr 00:0a:35:00:01:22` then `saveenv`.

---

## TFTP

### TFTP: Permission denied

```
TFTP error: 'Permission denied' (0)
Starting again
```

- **Good news:** the network works - the server answered.
- **Cause:** `namei -l /tftpboot/udoo/zImage` showed the folder as `drw-r--r--`. A folder without `x` cannot be entered, so the `tftp` user could not reach the file.
- **Fix:**
  ```bash
  sudo chmod 755 /tftpboot /tftpboot/udoo
  sudo chmod 644 /tftpboot/udoo/*
  ```
- **Lesson:** on a folder, `x` means "may enter". `namei -l` checks every step of a path at once.

### TFTP: T T T timeouts

- Check `ip addr show enp4s0` shows `192.168.7.1/24`.
- Check `sudo ufw status`; if active: `sudo ufw allow from 192.168.7.0/24`.
- Test locally: `tftp 192.168.7.1 -c get udoo/zImage`.

### TFTP folder contained another board's files

- **Cause:** `/tftpboot` already held a Zynq/PetaLinux `zImage` and `uImage`.
- **Fix:** one subfolder per board: `/tftpboot/udoo/`, loaded as `tftp <addr> udoo/zImage`.

---

## Kernel and NFS

### Kernel panic: VFS: Unable to mount root fs

```
Kernel panic - not syncing: VFS: Unable to mount root fs on unknown-block(0,0)
```

- **Meaning:** kernel and dtb work. The root filesystem is missing or unreachable.
- **Check:** `bootargs` has `root=/dev/nfs` and `nfsroot=...`; `sudo exportfs -v` lists `/srv/nfs/udoo`.
- **Lesson:** this panic was the *expected* result of the first kernel test.

### nfs: server not responding / hangs at mounting root

- **Cause:** NFS version mismatch - Ubuntu 24.04 has NFS v2 disabled.
- **Fix:** `nfsroot=192.168.7.1:/srv/nfs/udoo,v3,tcp`.
- **Check:** `sudo systemctl status nfs-kernel-server`.

### Kernel boots but no shell appears

- **Cause:** `inittab` names a BeagleBone console (`ttyO0`, `ttyS0`), or `rcS` is not executable.
- **Fix:** use `::askfirst:-/bin/sh` (empty console field = console from `bootargs`); `chmod +x /etc/init.d/*`.

### fsl-ssi-dai / sound: deferred probe pending

- **Harmless.** The audio interface waits for a codec driver that is not built. Ignore unless audio is needed.

---

## Init scripts

### Services do not start at boot, but work when run by hand

- **Check:** boot log lines between `Mounting proc` and `Please press Enter`.
- **Cause:** a script is not executable (the course `rcS` runs `$i start` directly → `Permission denied`),
  or `inittab` has no `::sysinit:/etc/init.d/rcS`.
- **Fix:** `sudo chmod +x /srv/nfs/udoo/etc/init.d/*`; check `inittab`.

### ifup: can't open '/var/run/ifstate.new'

```
ifup: can't open '/var/run/ifstate.new': No such file or directory
```

- **Cause:** `/var/run` did not exist. `ifup` stores its state there and **stops completely** when it cannot write it -
  so every interface after the first one is never started.
- **Fix:** `rcS` creates `/var/run /var/log /run` before running the services.
- **Lesson:** one missing folder can silently stop a whole chain.

### ip: RTNETLINK answers: File exists (when starting lo)

- **Cause:** the kernel had already given `lo` the address `127.0.0.1` while processing `ip=`; Linux refuses to add it twice.
- **Fix:** `S40network` runs `ip addr flush dev lo` before `ifup -a`.

### ifup skips interfaces after a reboot

- **Cause:** the rootfs is on NFS, so `/var/run/ifstate` **survives reboots**. `ifup` reads it and thinks the interfaces are already up.
- **Fix:** `S40network` removes `/var/run/ifstate` at start.

### Never make eth0 "auto" with an NFS root

- **Why:** `ifdown -a` at shutdown (or `S40network restart`) would take `eth0` down - the board loses its root filesystem and freezes.
- **Rule:** with NFS root, `eth0` is configured only by the kernel (`ip=`). Add `auto eth0` only for standalone boot.

---

## Kernel modules and usb0

### lsmod is empty / modprobe: module g_ether not found

- **Cause:** modules were not installed properly, so `/lib/modules/6.6.21/modules.dep` is missing.
- **Fix (laptop):**
  ```bash
  sudo make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=/srv/nfs/udoo modules_install
  ```
  Or on the board once: `depmod`.
- **Also check:** `uname -r` matches the folder name in `/lib/modules/` exactly (e.g. not `6.6.21-dirty`).
- **Lesson:** use `modprobe` (loads dependencies via `modules.dep`), not a chain of `insmod`.

### usb0 is UP but not RUNNING

- **Cause:** no USB link - cable missing, or plugged into the serial (CP2104) port instead of the **OTG** port.

### Laptop interface name changes every boot

- **Cause:** `g_ether` picks random MACs; Ubuntu names the interface `enx` + MAC.
- **Fix:** fixed MACs in `S02module`: `dev_addr=02:00:00:00:06:02 host_addr=02:00:00:00:06:01` → always `enx020000000601`.

### usb0 is RUNNING but ping 192.168.6.1 fails

- **Clue:** `usb0` RX count keeps rising, TX stays low - the laptop is sending DHCP requests, so it has **no IP** on that interface.
- **Fix (laptop):**
  ```bash
  sudo nmcli con add type ethernet ifname enx020000000601 con-name udoo-usb \
      ipv4.method manual ipv4.addresses 192.168.6.1/24 ipv6.method disabled
  sudo nmcli con up udoo-usb
  ```
- **If still failing:** `nmcli con show` - delete any automatic `Wired connection N` on that interface;
  `sudo tcpdump -n -i enx020000000601 icmp` shows whether pings arrive.

---

## Debugging approach that worked

1. **Find the last stage that succeeded** (SPL line? U-Boot prompt? kernel log? panic?).
2. **Test each layer alone** - `ping` before `tftp`, a local `tftp get` before the board, the kernel panic before NFS.
3. **Read the exact error** - "Permission denied" from TFTP proved the network was fine.
4. **Check assumptions from the BeagleBone course** - device numbers, console names, file vs raw boot.
