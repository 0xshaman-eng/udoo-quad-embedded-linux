# 06 - Init System: rcS, rcK and S?? Scripts

**Goal:** start logging, kernel modules and networking automatically at boot - and stop them cleanly at shutdown -
using the SysV-style init scripts from the course, adapted for the UDOO.

---

## The boot flow

```
Power on
  │
  ▼
Kernel ──────────────────────────────── mounts NFS root, starts /sbin/init
  │
  ▼
/sbin/init (BusyBox, PID 1)
  │  reads
  ▼
/etc/inittab ────────────────────────── "::sysinit:/etc/init.d/rcS"
  │  runs
  ▼
/etc/init.d/rcS
  │  1. mounts proc, sys, dev, devpts, tmp
  │  2. creates /var/run, /var/log, /run
  │  3. loops over /etc/init.d/S??* in number order:
  │
  ├──► S01logging start
  │      └── starts syslogd + klogd → writes /var/log/messages
  │
  ├──► S02module start
  │      └── modprobe g_ether dev_addr=... host_addr=...
  │            └── uses /lib/modules/6.6.21/modules.dep
  │                  └── kernel creates the usb0 interface
  │
  └──► S40network start
         └── ifup -a
               │  reads
               ▼
         /etc/network/interfaces
               ├── auto lo   → 127.0.0.1
               ├── auto usb0 → 192.168.6.2 / 255.255.255.0
               └── eth0      → not auto, skipped (kernel set it up for NFS)
  │
  ▼
back to init → inittab "::askfirst:-/bin/sh"
  │
  ▼
"Please press Enter to activate this console."  →  ~ #
```

### Step by step

1. **Kernel** mounts the root filesystem from NFS and starts the first program, `/sbin/init` (PID 1).
2. **init reads `/etc/inittab`** - its instruction list. The `sysinit` line says: run `/etc/init.d/rcS` once and wait.
3. **`rcS` prepares the system** - mounts `/proc`, `/sys`, `/dev`, `/dev/pts`, `/tmp` and creates `/var/run`, `/var/log`.
4. **`rcS` runs every `S??*` script** in `/etc/init.d/` with `start`, in number order:

| Order | Script | What it does | Reads / uses |
|---|---|---|---|
| 1st | `S01logging` | Starts `syslogd` (system log) and `klogd` (kernel messages) | Writes `/var/log/messages`, PID files in `/var/run` |
| 2nd | `S02module` | Loads the `g_ether` driver with fixed MAC addresses | `/lib/modules/6.6.21/modules.dep`; the kernel then creates `usb0` |
| 3rd | `S40network` | Runs `ifup -a` | `/etc/network/interfaces` |

5. **`ifup -a` reads `/etc/network/interfaces`** and starts every interface marked `auto`:

| Interface | In the file | Result |
|---|---|---|
| `lo` | `auto lo` / `inet loopback` | `127.0.0.1` |
| `usb0` | `auto usb0` / `inet static` | `192.168.6.2` |
| `eth0` | `iface eth0 ...` **without** `auto` | Skipped - the kernel set it up via `ip=`, and the NFS root depends on it |

6. **Back to init** - the `askfirst` line starts a shell on the console.

**Why this order:** logging starts first so it records everything after it. Modules load before the
network because `usb0` only exists once `g_ether` is loaded.

---

## The shutdown flow

```
poweroff / reboot
  │
  ▼
init reads /etc/inittab → "::shutdown:/etc/init.d/rcK"
  │
  ▼
rcK runs the S scripts in REVERSE order with "stop":
  ├── S40network stop → ifdown -a  (usb0, lo down; eth0 untouched)
  ├── S02module stop  → rmmod g_ether  (usb0 disappears)
  └── S01logging stop → syslogd + klogd stop (last, so they log everything)
  │
  ▼
"::shutdown:/bin/umount -a -r" → filesystems unmounted
```

---

## Why it is built this way

Each file has **one job** and only knows the next step:

| File | Job |
|---|---|
| `/etc/inittab` | **What** to run at boot and shutdown |
| `/etc/init.d/rcS` / `rcK` | **Order** - start / stop all S scripts |
| `/etc/init.d/S??*` | **How** to start and stop one service |
| `/etc/network/interfaces` | **Settings** - IPs, netmasks, which interfaces are automatic |
| `/lib/modules/<version>/modules.dep` | **Where** modules are and what they depend on |

- **New service** → add one `S` file (e.g. `S50sshd`). `rcS` finds it automatically.
- **New IP or interface** → edit `interfaces`. No script changes.

The same design is used by Buildroot, Yocto (SysV init) and older Debian systems.

---

## The files

All files are in [`rootfs/overlay/`](../rootfs/overlay/) and installed by `scripts/setup-nfs-rootfs.sh`.
They are the course (Buildroot-style) scripts; every UDOO change is marked `# UDOO:`.

### [`etc/inittab`](../rootfs/overlay/etc/inittab)

```
::sysinit:/etc/init.d/rcS
::askfirst:-/bin/sh
::restart:/sbin/init
::shutdown:/etc/init.d/rcK
::shutdown:/bin/umount -a -r
```

The console field (before `::`) is empty, so init uses the console from `bootargs` - `ttymxc1` on the UDOO.

### [`etc/init.d/rcS`](../rootfs/overlay/etc/init.d/rcS)

| Part | UDOO change? | Why |
|---|---|---|
| `mount -t proc` | course | Process information |
| `mount sysfs, devtmpfs, devpts, tmpfs` | **UDOO** | Kernel info, device files, SSH terminals, temp files |
| `mkdir -p /var/run /var/log /run` | **UDOO** | `start-stop-daemon` PID files, `ifup` state, logs |
| `for i in /etc/init.d/S??*` → `$i start` | course | Start every service in number order |

### [`etc/init.d/rcK`](../rootfs/overlay/etc/init.d/rcK)

Unchanged from the course: `ls -r` reverses the order, each script gets `stop`.

### [`etc/init.d/S01logging`](../rootfs/overlay/etc/init.d/S01logging)

Unchanged from the course. Uses `start-stop-daemon` to run `syslogd -n` and `klogd -n` in the background
with PID files in `/var/run`. Optional overrides in `/etc/default/logging`.

### [`etc/init.d/S02module`](../rootfs/overlay/etc/init.d/S02module)

| Part | UDOO change? | Why |
|---|---|---|
| `G_ETHER_ARGS="dev_addr=... host_addr=..."` | **UDOO** | Fixed MACs → the laptop always sees the same interface name |
| `[ -f .../modules.dep ] \|\| depmod` | **UDOO** | Builds the module index if missing |
| `modprobe g_ether` / `rmmod g_ether` | course | Load / unload the USB gadget driver |

### [`etc/init.d/S40network`](../rootfs/overlay/etc/init.d/S40network)

| Part | UDOO change? | Why |
|---|---|---|
| `rm -f /var/run/ifstate` | **UDOO** | The rootfs is on NFS, so `ifup`'s state file survives reboots - stale state makes `ifup` skip interfaces |
| `ip addr flush dev lo` | **UDOO** | The kernel already set `127.0.0.1` (`ip=`); without this `ifup lo` fails with "File exists" |
| `[ -e /sys/class/net/usb0 ] \|\| sleep 1` | **UDOO** | Gives `g_ether` time to create `usb0` |
| `ifup -a` / `ifdown -a` | course | Start / stop all `auto` interfaces |

### [`etc/network/interfaces`](../rootfs/overlay/etc/network/interfaces)

```
auto lo
iface lo inet loopback

auto usb0
iface usb0 inet static
    address 192.168.6.2
    netmask 255.255.255.0
    network 192.168.6.0
    broadcast 192.168.6.255

iface eth0 inet static          # NOT auto - root filesystem is on NFS over eth0
    address 192.168.7.2
    netmask 255.255.255.0
    network 192.168.7.0
    broadcast 192.168.7.255
    gateway 192.168.7.1
```

| Keyword | Meaning |
|---|---|
| `auto <if>` | Started by `ifup -a`, stopped by `ifdown -a` |
| `inet loopback` / `inet static` | Loopback / fixed IP (no DHCP) |
| `address`, `netmask` | This board's IP and network size |
| `network`, `broadcast` | Network base address and "send to all" address |
| `gateway` | Route to other networks - only one interface should have it |

> ⚠️ **`eth0` must not be `auto` while the root filesystem is on NFS.** `ifdown -a` at shutdown would
> take it down and the board would lose its root filesystem. For standalone SD card boot later, add `auto eth0`.

---

## Install

```bash
./scripts/setup-nfs-rootfs.sh
ls -l /srv/nfs/udoo/etc/init.d
```

All scripts must be executable (`-rwxr-xr-x`) - the course `rcS` runs them directly, so a missing `x`
gives `Permission denied` at boot.

---

## Verify

Boot log:

```
Mounting proc
Mounting sysfs, devtmpfs, devpts, tmpfs
Starting logging: OK
Loading kernel modules : OK
Starting network: OK

Please press Enter to activate this console.
```

On the board, without typing anything else first:

```
~ # ps | grep -E "syslogd|klogd"
  116 0         0:00 /sbin/syslogd -n
  119 0         0:00 /sbin/klogd -n
~ # lsmod
g_ether 12288 0 - Live 0xbf000000
~ # ifconfig usb0
usb0      Link encap:Ethernet  HWaddr 02:00:00:00:06:02
          inet addr:192.168.6.2  Bcast:192.168.6.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
```

Low PIDs (116, 119) show the daemons were started during boot by `rcS`, not by hand.

### Control services by hand

```
~ # /etc/init.d/S01logging restart
~ # /etc/init.d/S40network stop
~ # /etc/init.d/S40network start
~ # logger "hello from UDOO" && tail /var/log/messages
```

Watch the board's log live from the laptop (it is on NFS):

```bash
sudo tail -f /srv/nfs/udoo/var/log/messages
```

---

## Add a new service

1. Create `/etc/init.d/SNNname` with `start`, `stop` and `restart` cases (copy `S02module` as a template).
2. Pick the number by dependency - e.g. an SSH server needs the network, so `S50sshd` (after `S40`).
3. `chmod +x` it. `rcS` and `rcK` pick it up automatically.

Always use **two digits** - the order is alphabetical, so `S5` would run *after* `S40`.
