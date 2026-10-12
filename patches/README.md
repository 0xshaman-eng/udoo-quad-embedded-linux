# patches/

Changes made to upstream source code (U-Boot, Linux, BusyBox), kept as patch files
instead of committing whole source trees.

## Create a patch

Inside the source tree (after `git init && git add . && git commit -m base` on a clean extract,
or in a git clone of the upstream project):

```bash
git commit -am "udoo: describe the change"
git format-patch -1 -o /path/to/this/repo/patches/linux/
```

## Apply a patch

```bash
cd linux-6.6.21
patch -p1 < /path/to/this/repo/patches/linux/0001-udoo-describe-the-change.patch
```

Suggested layout:

```
patches/
├── u-boot/
├── linux/
└── busybox/
```

*(No patches yet - everything so far builds from unmodified upstream sources.)*
