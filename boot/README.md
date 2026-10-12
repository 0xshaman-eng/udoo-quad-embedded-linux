# boot/

Files used by U-Boot.

| File | Where it goes | Purpose |
|---|---|---|
| `uEnv.txt` | SD card, FAT partition (`mmc 2:1`) | Network boot: kernel + dtb over TFTP, rootfs over NFS |

## One-time U-Boot setup

The UDOO's U-Boot does not load `uEnv.txt` by itself (the BeagleBone's does).
Run this once at the U-Boot prompt:

```
=> setenv bootcmd 'fatload mmc 2:1 0x11000000 uEnv.txt; env import -t 0x11000000 ${filesize}; run uenvcmd'
=> saveenv
```

See [docs/04-network-boot.md](../docs/04-network-boot.md) for the full explanation.

> Save `uEnv.txt` with Unix (LF) line endings. Windows (CRLF) line endings break `env import`.
