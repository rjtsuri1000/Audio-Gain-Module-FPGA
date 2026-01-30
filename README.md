# Gain Module (AXI-Stream) on FPGA

This repository provides a **reference RTL implementation** of a
**stereo fixed-point gain stage**
implemented in **Verilog** and integrated with **AXI-Stream** and **AXI-Lite**.

Target platform: **AMD Kria KV260**  
Focus: **RTL architecture, fixed-point DSP decisions, and AXI correctness**

---

## Overview

This module implements:

* **Function**: Per-sample amplitude scaling (gain control)
* **Data type**: Fixed-point **Q4.12**
* **Scope**: Minimal, single-purpose DSP building block

The design is intentionally **not generic** and **not feature-rich**.  
It exists to demonstrate **how a gain stage is implemented in hardware**, not to provide a turnkey audio solution.

---

## Key Characteristics

* RTL written in **Verilog**
* **AXI-Stream** data interface (audio path)
* **AXI-Lite** control interface (gain & enable)
* Fixed-point arithmetic with explicit bit-width control
* Deterministic, cycle-accurate behavior
* Designed and verified for **real-time audio streaming**
* No software runtime included

---

## Architecture

High-level structure:
```
AXI-Stream In (Stereo)
|
v
+----------------------+
| Gain Core          |
| - Fixed-point mult |
| - Scaling (Q4.12)  |
| - Saturation       |
+----------------------+
|
v
AXI-Stream Out (Stereo)
```

Design notes:

* Processing is **fully synchronous**
* Gain arithmetic is isolated in a dedicated core (`gain_core`)
* AXI protocol handling is separated in a wrapper (`gain_axis_wrapper`)
* No hidden state outside the RTL

---

## Data Format

* AXI-Stream width: **32-bit**
* Audio samples:
  * Signed **16-bit**
  * Stereo, interleaved:
    * `[15:0]`  → Left
    * `[31:16]` → Right
* Gain format:
  * Signed fixed-point **Q4.12**
  * Stored in AXI-Lite registers

---

## Latency

* **Fixed processing latency**: **2 clock cycles**
  * 1 cycle: gain core
  * 1 cycle: AXI-Stream pipeline register

Latency is:

* deterministic
* independent of input signal
* independent of gain value

This behavior is intentional and suitable for streaming DSP pipelines.

---

## Control Interface (AXI-Lite)

The control interface exposes three registers:

| Offset | Register  | Description |
|-------:|----------|-------------|
| 0x00   | CONTROL  | Enable / bypass |
| 0x04   | GAIN_L   | Left-channel gain |
| 0x08   | GAIN_R   | Right-channel gain |

* `ENABLE = 0` → bypass mode (output = input)
* Gain registers use **Q4.12** format
* Upper bits of 32-bit registers are ignored

Detailed documentation is available in `/docs/address_map.md`.

---

## Verification & Validation

Verification was performed at two levels:

### 1. RTL Simulation

Dedicated SystemVerilog testbenches verify:

* Fixed-point arithmetic correctness
* Saturation and clipping behavior
* Clock enable (CE) handling
* AXI-Stream handshake correctness
* AXI-Lite register access

Simulation results are provided as CSV files and plotted waveforms
(see `/results`).

---

### 2. Hardware Validation

The design was **tested on real FPGA hardware**.

> **Tested on FPGA hardware via PYNQ overlay**

PYNQ was used only as:

* signal stimulus
* observability tool

Python scripts, bitstreams, and hardware handoff files are **intentionally not published** to keep the repository focused on RTL architecture.

---

## Design Rationale (Summary)

Key design decisions:

* **Fixed-point Q4.12** chosen for predictable scaling and saturation
* Explicit **bypass mode** instead of gain = 1.0
* Saturation applied after scaling to prevent wraparound
* Minimal register set to avoid unnecessary control complexity
* No dynamic reconfiguration or smoothing logic

These decisions reflect **engineering trade-offs**, not missing features.

More detailed explanations are available in `/docs/design_rationale.md`.

---

## What This Repository Is

* A **clean RTL reference**
* A demonstration of:
  * fixed-point DSP reasoning
  * saturation-safe arithmetic
  * AXI-Stream and AXI-Lite integration
* A reusable building block for larger FPGA audio pipelines

---

## What This Repository Is Not

* ❌ A complete audio processing system
* ❌ A feature-rich or generic IP core
* ❌ A software-driven demo
* ❌ A drop-in commercial product

The scope is intentionally constrained.

---

## Project Status

This repository is considered **complete**.

* RTL is stable
* Simulation coverage is sufficient
* Hardware validation has been performed
* No further feature development is planned

The design is published as a **reference implementation**.

---

## Documentation

Additional documentation is available in `/docs`:

* `address_map.md`
* `build_overview.md`
* `design_rationale.md`
* `latency_and_data_format.md`
* `validation_notes.md`

---

## License

Licensed under the MIT License.  
Provided as-is, without warranty.

---

## Notes

> **This repository demonstrates design decisions, not design possibilities.**
