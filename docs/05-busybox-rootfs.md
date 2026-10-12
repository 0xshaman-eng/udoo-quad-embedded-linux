# 05 - BusyBox Root Filesystem

**Goal:** build a minimal root filesystem with BusyBox and serve it to the board over NFS.

---

## Theory

### What BusyBox is

One small binary that contains hundreds of Unix tools (`sh`, `ls`, `mount`, `init`, `ifup`, `modprobe`, `syslogd`...).
`make install` creates **symlinks** (`/bin/ls → busybox`); BusyBox checks the name it was
called with and acts as that tool.

### Static vs dynamic

| | Static (this project) | Dynamic |
|---|---|---|
| C library | Inside the binary | Separate files in `/lib` |
| Extra files needed | None | `ld-linux-armhf.so.3`, `libc.so.6`, `libm.so.6`, `libresolv.so.2` |
| Binary size | Bigger | Smaller |
| Shared by many programs | No | Yes - saves space with many apps |
| Easiest to move between boards | ✅ | Needs matching libraries |

### Does the root filesystem depend on the board?

Mostly **no** - it depends on the **CPU architecture and ABI**:

| Depends on | Example |
|---|---|
| Instruction set | ARMv7 (UDOO, BeagleBone, Zynq-7000) vs ARMv8 vs x86-64 |
| ABI | `gnueabihf` (hard-float) vs `gnueabi` (soft-float) - cannot mix |
| C library | glibc / musl version (dynamic builds only) |

Board-specific parts are small: console name, kernel modules, firmware, device names in scripts.
The same static BusyBox built for a BeagleBone course runs on the UDOO.

---

## Steps

### 1. Build BusyBox

```bash
./scripts/build-busybox.sh
```

| Setting | Why |
|---|---|
| `CONFIG_STATIC=y` | No libraries needed in the rootfs (menuconfig: *Settings → Build static binary*) |
| `CONFIG_TC` off | `tc` fails to build against Ubuntu 24.04 kernel headers |
| `CONFIG_PREFIX=` | Where `make install` puts `bin/ sbin/ usr/ linuxrc` |

Check:

```bash
file ~/Udoo_Workspace/RFS_Static/bin/busybox
# ELF 32-bit LSB executable, ARM, EABI5 ... statically linked
```

### 2. Build the complete root filesystem in the NFS folder

```bash
./scripts/setup-nfs-rootfs.sh
```

`make install` only creates `bin sbin usr linuxrc`. The script adds everything else:

| Added | Purpose |
|---|---|
| `dev/ proc/ sys/ tmp/` | Mount points for device files, process info, kernel info, temp files |
| `run/ var/run/ var/log/` | PID files, `ifup` state, log files |
| `root/` | Home folder of the root user |
| `etc/inittab`, `etc/init.d/*` | Init system - see [06-init-system](06-init-system.md) |
| `etc/network/interfaces` + hook folders | Network config - see [06](06-init-system.md) and [07](07-usb-gadget-network.md) |
| `lib/modules/6.6.21/` | Kernel modules + `modules.dep` (see [03-kernel](03-kernel.md)) |

Result on the laptop:

```bash
ls /srv/nfs/udoo
# bin  dev  etc  lib  linuxrc  proc  root  run  sbin  sys  tmp  usr  var
```

---

## Verify

Boot the board (see [04-network-boot](04-network-boot.md)):

```
~ # uname -a
Linux udoo 6.6.21 #1 SMP ... armv7l GNU/Linux
~ # ls /
bin      etc      linuxrc  root     sbin     tmp      var
dev      lib      proc     run      sys      usr
```

Live NFS test - on the laptop:

```bash
echo "hello from laptop" | sudo tee /srv/nfs/udoo/root/test.txt
```

On the board, `cat /root/test.txt` shows it instantly.

Harmless messages during boot:

```
fsl-ssi-dai 2028000.ssi: No cache defaults, reading back from HW
platform sound: deferred probe pending
```

The audio interface waits for a codec driver that is not built. Ignore unless audio is needed.
