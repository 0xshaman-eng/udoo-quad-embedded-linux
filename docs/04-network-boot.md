# 04 - Network Boot: TFTP, NFS and uEnv.txt

**Goal:** boot the UDOO with the kernel loaded over TFTP and the root filesystem mounted over NFS - automatically at power-on.

---

## Theory

| | TFTP | NFS |
|---|---|---|
| Used by | U-Boot | Linux kernel |
| Transfers | Single files into RAM | A whole folder, mounted as `/` |
| Benefit | New kernel = copy one file, reset | Edit files on the laptop, board sees them instantly |

```
  Phone hotspot (internet)
          |  USB tethering
  +-------+----------+   Ethernet (direct)  +----------------+
  |     Laptop       |----------------------|   UDOO Quad    |
  |  192.168.7.1     |                      |  192.168.7.2   |
  |  TFTP + NFS      |   micro-USB serial   |                |
  +------------------+----------------------+----------------+
```

A direct cable makes a private network: no router needed, internet stays on the hotspot.

---

## Steps

### 1. Static IP on the laptop's Ethernet port

```bash
ip link                       # enp*/eno* = Ethernet, wl* = Wi-Fi, enx* = USB tethering
sudo nmcli con add type ethernet ifname enp4s0 con-name udoo-link \
    ipv4.method manual ipv4.addresses 192.168.7.1/24
sudo nmcli con up udoo-link
```

No gateway on purpose - internet keeps using the hotspot.

### 2. TFTP server

```bash
cat /etc/default/tftpd-hpa    # TFTP_DIRECTORY - this setup uses /tftpboot
./scripts/deploy-tftp.sh      # copies zImage + dtb to /tftpboot/udoo
```

Files go in a `udoo/` subfolder so other boards' files in `/tftpboot` are not overwritten.

The server runs as user `tftp`, so **every folder needs `r-x` and every file `r--`** for others:

```bash
namei -l /tftpboot/udoo/zImage
tftp 192.168.7.1 -c get udoo/zImage      # local test, run in /tmp
```

### 3. NFS server

```bash
./scripts/setup-nfs-rootfs.sh
```

This adds to `/etc/exports`:

```
/srv/nfs/udoo 192.168.7.0/24(rw,sync,no_root_squash,no_subtree_check)
```

| Option | Why |
|---|---|
| `no_root_squash` | The board runs as root and must own files in its root filesystem |
| `sync` | Writes reach the disk before the server replies |
| `192.168.7.0/24` | Only the private board network can mount it |

### 4. First boot by hand

```
=> setenv ipaddr 192.168.7.2
=> setenv serverip 192.168.7.1
=> ping 192.168.7.1
=> tftp 0x12000000 udoo/zImage
=> tftp 0x18000000 udoo/imx6q-udoo.dtb
=> setenv bootargs console=ttymxc1,115200 root=/dev/nfs rw nfsroot=192.168.7.1:/srv/nfs/udoo,v3,tcp ip=192.168.7.2:192.168.7.1:192.168.7.1:255.255.255.0:udoo:eth0:off
=> bootz 0x12000000 - 0x18000000
```

**Load addresses:** DDR starts at `0x10000000`. Kernel at `0x12000000` and dtb at `0x18000000`
are inside RAM and 96 MB apart, so they cannot overlap.

### Kernel bootargs explained

| Part | Meaning |
|---|---|
| `console=ttymxc1,115200` | Kernel console on the UDOO debug UART |
| `root=/dev/nfs rw` | Root filesystem is NFS, read-write |
| `nfsroot=192.168.7.1:/srv/nfs/udoo,v3,tcp` | Server:folder, **NFS v3** over TCP |
| `ip=192.168.7.2:192.168.7.1:192.168.7.1:255.255.255.0:udoo:eth0:off` | client : server : gateway : netmask : hostname : interface : autoconf |

U-Boot's `ipaddr` is **not** passed to Linux - the kernel needs its own `ip=`.
**`v3` is required:** Ubuntu 24.04's NFS server has NFS v2 disabled.

### 5. Automatic boot with uEnv.txt

[`boot/uEnv.txt`](../boot/uEnv.txt) on the FAT partition:

```
ipaddr=192.168.7.2
serverip=192.168.7.1
kernel_addr=0x12000000
fdt_addr=0x18000000
bootargs=console=ttymxc1,115200 root=/dev/nfs rw nfsroot=192.168.7.1:/srv/nfs/udoo,v3,tcp ip=192.168.7.2:192.168.7.1:192.168.7.1:255.255.255.0:udoo:eth0:off
uenvcmd=tftp ${kernel_addr} udoo/zImage; tftp ${fdt_addr} udoo/imx6q-udoo.dtb; bootz ${kernel_addr} - ${fdt_addr}
```

The UDOO's U-Boot does not read `uEnv.txt` by itself, so set `bootcmd` **once**:

```
=> setenv bootcmd 'fatload mmc 2:1 0x11000000 uEnv.txt; env import -t 0x11000000 ${filesize}; run uenvcmd'
=> saveenv
=> reset
```

| Part | Meaning |
|---|---|
| `fatload mmc 2:1 0x11000000 uEnv.txt` | Read the text file into RAM |
| `env import -t <addr> ${filesize}` | Turn each `name=value` line into a variable |
| `run uenvcmd` | Execute the boot commands |
| Single quotes | Delay `${filesize}` expansion until boot time |

---

## Verify

Power on, press nothing. The board loads `uEnv.txt`, downloads the kernel and dtb, mounts the NFS root
and runs the init scripts ([06-init-system](06-init-system.md)):

```
Mounting proc
Mounting sysfs, devtmpfs, devpts, tmpfs
Starting logging: OK
Loading kernel modules : OK
Starting network: OK

Please press Enter to activate this console.
```

Live NFS test - on the laptop:

```bash
echo "hello from laptop" | sudo tee /srv/nfs/udoo/root/test.txt
```

On the board: `cat /root/test.txt` shows it instantly.

---

## UDOO vs BeagleBone

| | BeagleBone | UDOO Quad |
|---|---|---|
| Loads `uEnv.txt` automatically | Yes | No - `bootcmd` set once |
| Kernel boot command | `bootm` (uImage) | `bootz` (zImage) |
| Load addresses | `0x82000000`, `0x88000000` | `0x12000000`, `0x18000000` |

---

## Problems I hit

- TFTP `Permission denied` → [troubleshooting](troubleshooting.md#tftp-permission-denied)
- Kernel panic before NFS was set up → [troubleshooting](troubleshooting.md#kernel-panic-vfs-unable-to-mount-root-fs)
