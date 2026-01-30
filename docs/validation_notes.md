# Validation Notes

This document summarizes how the Gain module was validated.

---

## Simulation

Two levels of simulation were performed:

### 1. Core-Level Simulation
- Direct stimulus to `gain_core`
- Verifies:
  - Fixed-point math
  - Saturation
  - CE and bypass behavior

### 2. System-Level Simulation
- AXI-Stream + AXI-Lite wrapper
- Verifies:
  - AXI protocol correctness
  - Register control behavior
  - Streaming stability

Results are provided as CSV files with plotted waveforms.

---

## Hardware Validation

The design was validated on real hardware using:
- Kria KV260
- PYNQ overlay

Validation focused on:
- Continuous streaming stability
- Correct gain response
- No AXI deadlock under backpressure

---

## What Was Not Validated

- Long-term thermal behavior
- Power optimization
- Audio perceptual quality

These are outside the scope of this repository.
