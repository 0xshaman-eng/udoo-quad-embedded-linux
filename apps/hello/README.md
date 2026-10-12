# hello

First cross-compiled application.

```bash
make            # builds with arm-linux-gnueabihf-gcc, statically linked
file hello      # should say: ELF 32-bit LSB executable, ARM, EABI5 ... statically linked
make install    # copies to /srv/nfs/udoo/usr/bin/
```

On the UDOO:

```
~ # hello
Hello from UDOO Quad!
  Host name : udoo
  Kernel    : Linux 6.6.21
  Machine   : armv7l
```

**Why static?** The BusyBox rootfs has no C library in `/lib`, so a dynamically linked
program would fail with `not found`. Static linking puts the library inside the binary.
