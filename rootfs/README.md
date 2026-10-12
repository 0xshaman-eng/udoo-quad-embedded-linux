# rootfs/

`overlay/` holds the files **added on top of** the BusyBox install to make a working root filesystem.
All of them are tested on the UDOO Quad.

```
overlay/
└── etc/
    ├── inittab                 what init runs at boot and shutdown
    ├── init.d/
    │   ├── rcS                 boot: mount filesystems, start S?? scripts in order
    │   ├── rcK                 shutdown: stop S?? scripts in reverse order
    │   ├── S01logging          syslogd + klogd
    │   ├── S02module           loads g_ether (USB Ethernet gadget)
    │   └── S40network          ifup -a / ifdown -a
    └── network/
        └── interfaces          lo, usb0 (auto) and eth0 (not auto - NFS root)
```

Lines marked `# UDOO:` in the scripts are the changes made to the BeagleBone course versions.

Install with:

```bash
./scripts/setup-nfs-rootfs.sh
```

See [docs/06-init-system.md](../docs/06-init-system.md) and [docs/07-usb-gadget-network.md](../docs/07-usb-gadget-network.md).
