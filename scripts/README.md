# scripts/

Reproducible build and deploy scripts. All settings (versions, folders, IPs) live in [`config.sh`](config.sh).

| Script | What it does |
|---|---|
| `build-uboot.sh` | Downloads and builds U-Boot → `SPL` + `u-boot.img` |
| `build-kernel.sh` | Downloads and builds Linux → `zImage` + `imx6q-udoo.dtb` + modules |
| `build-busybox.sh` | Builds static BusyBox and installs it into `RFS_Static/` |
| `flash-sd.sh /dev/sdX` | Partitions the SD card, writes the bootloader, copies `uEnv.txt` |
| `deploy-tftp.sh` | Copies kernel + dtb to `/tftpboot/udoo` with the right permissions |
| `setup-nfs-rootfs.sh` | Exports `/srv/nfs/udoo`; installs BusyBox, folders, `rootfs/overlay` and kernel modules |
| `save-configs.sh` | Saves your U-Boot, kernel and BusyBox configs into `configs/` |

## Typical order

```bash
./scripts/build-uboot.sh
./scripts/build-kernel.sh
./scripts/build-busybox.sh
./scripts/flash-sd.sh /dev/sdX      # check the device with lsblk first!
./scripts/deploy-tftp.sh
./scripts/setup-nfs-rootfs.sh
```

## Change a setting

Override any value from `config.sh` on the command line:

```bash
WORKSPACE=~/work KERNEL_VERSION=6.6.50 ./scripts/build-kernel.sh
```

## Safety

`flash-sd.sh` refuses to run on a device that is not removable, is larger than 128 GB,
is a partition instead of a whole disk, or holds a system mount point. It also asks you to type `YES`.
