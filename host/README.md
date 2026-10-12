# host/

Configuration for the **laptop** (host) that serves the board over the network.

| File | Copy to | Purpose |
|---|---|---|
| `exports` | add the line to `/etc/exports` | NFS share for the root filesystem |
| `tftpd-hpa` | `/etc/default/tftpd-hpa` | TFTP server folder and options |

## Network links

| Link | Laptop interface | Laptop IP | UDOO |
|---|---|---|---|
| Ethernet (TFTP + NFS) | `enp4s0` (yours may differ) | `192.168.7.1/24` | `eth0` `192.168.7.2` |
| USB gadget | `enx020000000601` | `192.168.6.1/24` | `usb0` `192.168.6.2` |

```bash
# Ethernet link
sudo nmcli con add type ethernet ifname enp4s0 con-name udoo-link \
    ipv4.method manual ipv4.addresses 192.168.7.1/24

# USB gadget link
sudo nmcli con add type ethernet ifname enx020000000601 con-name udoo-usb \
    ipv4.method manual ipv4.addresses 192.168.6.1/24 ipv6.method disabled
```

See [docs/04-network-boot.md](../docs/04-network-boot.md).
