# apps/

User-space applications for the UDOO Quad. Each app has its own folder and Makefile.

| App | What it shows |
|---|---|
| [`hello/`](hello/) | Cross-compiling a C program and running it over NFS |

Planned: GPIO LED control, I2C sensor reading, serial link to the SAM3X for motor control.

## Build and install any app

```bash
cd apps/hello
make            # cross-compile for ARM
make install    # copy to /srv/nfs/udoo/usr/bin (appears on the board instantly)
```
