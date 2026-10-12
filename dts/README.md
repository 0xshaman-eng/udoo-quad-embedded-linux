# dts/

Custom device tree files for the UDOO Quad (coming in the device tree stage).

Planned:

- `imx6q-udoo-custom.dts` - includes the upstream `imx6q-udoo.dts` and enables extra hardware
  (for example an extra UART for a GNSS receiver, or GPIO/PWM for motors).

Upstream reference file: `arch/arm/boot/dts/nxp/imx/imx6q-udoo.dts` (Linux 6.5+).

> UDOO Quad header pins are shared between the i.MX6 and the SAM3X microcontroller.
> Check the UDOO pinout before driving a pin from Linux.
