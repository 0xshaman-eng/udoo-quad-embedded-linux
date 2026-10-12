# 07 - USB Gadget Networking (usb0)

**Goal:** a second network link between the laptop and the UDOO over a USB cable, started automatically at boot.

---

## Theory

With the **USB Ethernet gadget** driver (`g_ether`), the UDOO acts as a **USB network adapter**.
Plug it into the laptop and both sides get a network interface - IP traffic flows over the USB cable.

| Side | Interface | Address |
|---|---|---|
| UDOO | `usb0` | `192.168.6.2` |
| Laptop | `enx020000000601` | `192.168.6.1` |

The board is a USB **device** (gadget) here, not a USB host.

### Which USB port?

The UDOO Quad has **two** micro-USB ports:

| Port | Chip | Job |
|---|---|---|
| Debug port | CP2104 USB-UART | Serial console (`/dev/ttyUSB0`) |
| **OTG port** | i.MX6 USB controller | **USB gadget → `usb0`** |

Connect a **second** micro-USB cable to the **OTG** port.

### Two links, two jobs

```
  +------------------+   Ethernet  192.168.7.x   +----------------+
  |                  |---------------------------| eth0           |
  |     Laptop       |   USB OTG   192.168.6.x   |   UDOO Quad    |
  |                  |---------------------------| usb0           |
  |                  |   USB serial (console)    |                |
  |                  |---------------------------| ttymxc1        |
  +------------------+                           +----------------+
```

| Link | Used for |
|---|---|
| `eth0` | TFTP + NFS root filesystem - do not reconfigure it |
| `usb0` | Extra link: SSH, testing, file transfer |

### Why fixed MAC addresses?

By default `g_ether` makes up **random** MACs each time it loads. Ubuntu names USB network interfaces
`enx` + MAC, so the laptop interface name would change at every boot and its network settings would stop matching.

`S02module` loads it with fixed addresses:

```
g_ether dev_addr=02:00:00:00:06:02 host_addr=02:00:00:00:06:01
```

| Parameter | Side | Result |
|---|---|---|
| `dev_addr` | Board | `usb0` MAC `02:00:00:00:06:02` |
| `host_addr` | Laptop | Interface always named **`enx020000000601`** |

---

## Steps

### 1. Board side (automatic)

Already done by the init system ([06-init-system](06-init-system.md)):

- `S02module` → `modprobe g_ether` with fixed MACs (needs kernel modules installed - [03-kernel](03-kernel.md))
- `S40network` → `ifup -a` → `auto usb0` in `/etc/network/interfaces` → `192.168.6.2`

### 2. Laptop side (once)

Connect the OTG cable and boot the board, then:

```bash
ip -br link | grep enx020000000601
sudo nmcli con add type ethernet ifname enx020000000601 con-name udoo-usb \
    ipv4.method manual ipv4.addresses 192.168.6.1/24 ipv6.method disabled
sudo nmcli con up udoo-usb
```

The connection activates automatically every time the UDOO's USB link appears.

> Your phone's USB tethering is also an `enx...` interface (with a different MAC). Only configure `enx020000000601`.

---

## Verify

On the board:

```
~ # lsmod
g_ether 12288 0 - Live 0xbf000000
~ # ifconfig usb0
usb0      HWaddr 02:00:00:00:06:02
          inet addr:192.168.6.2  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST
~ # ping -c 3 192.168.6.1
3 packets transmitted, 3 packets received, 0% packet loss
```

On the laptop:

```bash
ip -br addr show enx020000000601     # enx020000000601  UP  192.168.6.1/24
ping -c 3 192.168.6.2
```

### Reading the interface flags

| Flags | Meaning |
|---|---|
| `UP BROADCAST MULTICAST` | Enabled, but **no link** - cable missing or wrong port |
| `UP BROADCAST RUNNING MULTICAST` | Enabled **and** connected |

Kernel messages when `g_ether` loads:

```
using host ethernet address: 02:00:00:00:06:01
using self ethernet address: 02:00:00:00:06:02
g_ether gadget.0: g_ether ready
```

---

## UDOO vs BeagleBone

| | BeagleBone | UDOO Quad |
|---|---|---|
| Driver | `g_ether` | `g_ether` (same) |
| Port | Mini-USB (also powers the board) | Micro-USB OTG (power from 12 V jack) |
| Loaded by | `S02module` | `S02module` + fixed MACs |
