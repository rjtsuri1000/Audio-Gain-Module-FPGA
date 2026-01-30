# Address Map – Gain Module

This document describes the **AXI4-Lite register map** of the Gain module.

The register interface is intentionally minimal and designed for:
- Low-latency control
- Predictable behavior
- Ease of integration into AXI-based systems

---

## AXI4-Lite Base Address

The base address is assigned by the system integrator (e.g. Vivado Block Design).
Only the **offsets** are defined here.

---

## Register Map

| Offset | Name        | Access | Description |
|-------:|------------|--------|-------------|
| 0x00   | CONTROL    | R/W    | Control register |
| 0x04   | GAIN_L     | R/W    | Left-channel gain |
| 0x08   | GAIN_R     | R/W    | Right-channel gain |

Unused addresses are reserved and return zero on read.

---

## Register Definitions

### CONTROL (0x00)

| Bit | Name    | Description |
|----:|---------|-------------|
| 0   | ENABLE  | `1` = enable gain, `0` = bypass |
| 31:1| —       | Reserved |

When `ENABLE = 0`, the module operates in **bypass mode** and the gain registers
have no effect on the output.

---

### GAIN_L / GAIN_R (0x04 / 0x08)

- Signed fixed-point value
- Format: **Q4.12**
- Width: 16-bit (LSBs used)

Examples:

| Gain | Hex Value | Decimal |
|------|-----------|---------|
| 0.5  | 0x0800    | 2048 |
| 1.0  | 0x1000    | 4096 |
| 2.0  | 0x2000    | 8192 |

Upper bits of the 32-bit register are ignored.

---

## Notes

- No shadow registers or update handshake is used.
- Gain updates take effect synchronously with the AXI clock.
- Software is expected to avoid mid-frame gain changes if glitch-free audio
  is required.
