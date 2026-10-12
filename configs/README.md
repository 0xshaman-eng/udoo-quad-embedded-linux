# configs/

Saved build configurations, so anyone can rebuild exactly what runs on the board.

Fill this folder by running:

```bash
./scripts/save-configs.sh
```

| File | Comes from | Created with |
|---|---|---|
| `u-boot-<version>_udoo_defconfig` | U-Boot source tree | `make savedefconfig` |
| `linux-<version>_udoo_defconfig` | Linux source tree | `make savedefconfig` |
| `busybox-<version>.config` | BusyBox source tree | full `.config` (BusyBox has no `savedefconfig`) |

**Why `savedefconfig`?** It saves only the options that differ from the defaults.
A few dozen lines instead of thousands, so changes are easy to see in Git.

The build scripts in `scripts/` use these files automatically when they exist.
