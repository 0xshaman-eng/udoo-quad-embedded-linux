# logs/

Real serial console logs captured from the board - proof that each stage runs on hardware.

## Capture a boot log

```bash
sudo picocom -b 115200 --logfile logs/network-boot.log /dev/ttyUSB0
```

Then power on the board. Exit picocom with `Ctrl+A`, `Ctrl+X`.

Suggested files:

| File | Stage |
|---|---|
| `u-boot-prompt.log` | U-Boot reaching the `=>` prompt |
| `network-boot.log` | Full automatic boot: uEnv.txt, TFTP, NFS, BusyBox shell |
| `standalone-boot.log` | Boot from SD card only (later) |
