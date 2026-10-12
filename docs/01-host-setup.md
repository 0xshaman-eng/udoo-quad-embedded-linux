# 01 - Host Setup

**Goal:** prepare an Ubuntu 24.04 laptop to cross-compile for the UDOO Quad and serve it over the network.

---

## Theory: cross-compiling

The laptop is **x86-64**; the UDOO is **32-bit ARM (ARMv7 Cortex-A9, hard-float)**.
A **cross compiler** runs on the laptop but produces ARM code.

| Prefix part | Meaning |
|---|---|
| `arm` | 32-bit ARM |
| `linux` | Target runs Linux |
| `gnueabihf` | GNU C library, ARM EABI, **h**ard-**f**loat (FPU registers used for float arguments) |

The same toolchain works for the BeagleBone (Cortex-A8) and Zynq-7000 (Cortex-A9).

---

## Steps

```bash
sudo apt update
sudo apt install build-essential gcc-arm-linux-gnueabihf \
    bison flex bc libssl-dev libncurses-dev libgnutls28-dev \
    python3-setuptools python3-pyelftools swig u-boot-tools \
    picocom tftpd-hpa tftp-hpa nfs-kernel-server
```

| Package | Needed for |
|---|---|
| `gcc-arm-linux-gnueabihf` | Cross compiler |
| `bison flex bc libssl-dev` | Kernel and U-Boot build |
| `libncurses-dev` | `make menuconfig` |
| `libgnutls28-dev python3-* swig` | U-Boot 2024 host tools and binman |
| `u-boot-tools` | `mkimage` (only for uImage / boot scripts) |
| `picocom` | Serial console |
| `tftpd-hpa tftp-hpa` | TFTP server + test client |
| `nfs-kernel-server` | NFS server |

Workspace for source trees (kept **outside** this repo):

```bash
mkdir -p ~/Udoo_Workspace
```

---

## Verify

```bash
arm-linux-gnueabihf-gcc --version
```

---

## Problems I hit

- **apt locked by `unattended-upgr`** - see [troubleshooting](troubleshooting.md#apt-is-locked-by-unattended-upgr).
