# RoT + SRAM PUF Test Plan

## Overview

This plan characterizes the Low-Power Root of Trust (RoT) chip: an OpenTitan-derived secure boot controller (Ibex core + TL-UL crossbar + UART + QSPI external memory interface) with an SRAM Physically Unclonable Function (PUF) used for runtime ECDSA (secp160r1) key derivation during secure boot. The design targets a 1000µm × 1000µm die on GF180MCU 180nm, taped out through the SSCS open-source chipathon program.


## Test Setup

The DUT is the packaged RoT chip, mounted on a breakout/test PCB exposing clk\_i, rst\_ni, the UART pins, and the QSPI pins (sclk, cs\_n, io\[0:3\]).

| Equipment | Purpose |
| --- | --- |
| 3.3V regulated power supply | Core/IO supply for the DUT |
| Precision clock source (85ns period / 11.76MHz nominal) | Drives clk\_i; must be adjustable for the Test 4 margin sweep |
| 4+ channel digital oscilloscope or logic analyzer | Captures QSPI (sclk, cs\_n, io\[0:3\]) and UART timing |
| USB-to-UART (e.g. FTDI) adapter + host PC terminal | Reads boot-log/status output from uart\_tx\_o |
| QSPI memory device or FPGA-emulated QSPI slave | Holds the firmware image(s) fetched by the DUT over QSPI — must support loading both a validly-signed image and a deliberately-corrupted one |
| Current probe or precision shunt + multimeter | Supply current measurement for Test 6 |

## Test 1: Power-On and Secure Boot Verification

With the correctly-signed firmware image loaded on the QSPI slave, power up the DUT, hold rst\_ni low for a fixed settle period, then release it. Capture the UART output and confirm the boot sequence reaches the expected "verify OK" status, indicating the ROM successfully fetched BL0 over QSPI, computed its digest, and validated the ECDSA (secp160r1) signature against the embedded public key.

Repeat with the deliberately-corrupted (bad-signature) image loaded instead, and confirm the boot sequence halts/rejects rather than proceeding.

## Test 2: SRAM PUF Key Derivation Functional Test

Using a debug/probe build of the ROM firmware (one that reports the derived public key over UART rather than only using it internally), power up the DUT and record the PUF-derived key. Power-cycle the DUT and repeat several times, confirming the same key is derived from the same die on every cycle — this is the basic functional check that the PUF reliably regenerates a stable key rather than a different value each boot.

## Test 3: Clock/Timing Margin Verification

The design was synthesized and signed off at an 85ns clock period (11.76MHz), with roughly 12.5ns of setup margin reported by static timing analysis. With the correctly-signed firmware loaded, sweep the clk\_i period down from the nominal 85ns in small steps, re-running the Test 1 boot sequence at each step, until secure boot first fails (corrupted fetch, signature mismatch, or hang).


## Test 4: QSPI External Memory Interface Functional Test

With the logic analyzer capturing sclk, cs\_n, and io\[0:3\] during a normal boot sequence, verify the QSPI protocol against its specification:

- A cold/non-sequential access shows the full 20-nibble sequence (2 nibbles command, 6 nibbles address, 4 dummy nibbles, 8 nibbles data), with cs\_n held low throughout.
- A read immediately following a prior read at the next sequential address skips straight to the 8-nibble data phase (the continuous-read fast path), with cs\_n never released between the two.
- sclk runs at half the frequency of clk\_i.
- A non-sequential access (e.g. following a branch) correctly falls back to the full cold-access sequence rather than incorrectly chaining.

## Test 5: Power Consumption Characterization

Using a current probe or precision shunt in series with the 3.3V supply, measure:

- Static (idle, clock stopped or gated) supply current.
- Dynamic average current during the full secure-boot sequence (
Test 1), which is QSPI-fetch-heavy and the most active phase of operation.
- Dynamic average current during the PUF read/key-derivation step specifically, if separable from the rest of boot.

## Important Operating Notes

- rst\_ni must be held low long enough for the PUF to settle before release; if the design has a documented minimum settle time, hold for at least that long.
- PUF responses are specific to the exact die under test, at its current temperature and supply voltage — do not expect bit-identical results on a different physical sample, or necessarily on the same sample at a different temperature/voltage.

## Known Limitations

This plan characterizes PUF behavior only on the die(s) available to this team. It cannot establish the population-level metrics a production PUF qualification would require:

- **Inter-die uniqueness** (Hamming distance between responses from many different dies) needs dozens to hundreds of samples.
- **Full PVT corner coverage** (temperature sweep via thermal chamber, supply voltage sweep) is not attempted — this plan assumes room temperature and nominal 3.3V supply throughout.

