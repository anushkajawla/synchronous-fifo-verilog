# Synchronous FIFO using Verilog

## Project Overview

This project implements a synchronous First-In, First-Out (FIFO) buffer using Verilog HDL. The FIFO stores four 8-bit data entries and returns them in the order they were written.

The project includes a Verilog design, a directed Verilog testbench, and a self-checking SystemVerilog testbench with a reference-model scoreboard, randomized stimulus, procedural assertion-style checks, and functional coverage counters.

## Features

- 8-bit data width and four storage locations
- Synchronous read and write operations
- Read and write pointers with wraparound
- Full and empty status flags
- Protection against writes when full and reads when empty
- Directed functional testing using Verilog
- Self-checking SystemVerilog verification
- Reference-model scoreboard for checking FIFO output data
- Randomized read/write stimulus
- Procedural assertion-style safety checks
- Functional coverage counters for FIFO occupancy, blocked operations, simultaneous requests, and pointer wraparound

## Module Ports

| Port | Direction | Description |
|---|---|---|
| `clk` | Input | Clock signal |
| `rst` | Input | Active-high synchronous reset |
| `wr_en` | Input | Write enable |
| `rd_en` | Input | Read enable |
| `din` | Input | 8-bit input data |
| `dout` | Output | 8-bit output data |
| `full` | Output | Indicates the FIFO is full |
| `empty` | Output | Indicates the FIFO is empty |

## How It Works

The memory array stores the data. The write pointer identifies the next location to write, and the read pointer identifies the next entry to read. Both pointers wrap around to location zero after reaching the last location.

A counter tracks the number of stored entries. The `full` flag is asserted when the FIFO contains four entries, and `empty` is asserted when it contains no entries.

The synchronous reset clears the pointers, counter, and output at a rising clock edge when reset is active. Writes are blocked when the FIFO is full, and reads are blocked when it is empty. When a valid read and write occur together, the occupancy count remains unchanged.

## Verification

### 1. Directed Verilog Testbench

The original Verilog testbench checks basic FIFO functionality, including:

- Writing four data values
- Checking the full flag
- Blocking an additional write when full
- Reading values in FIFO order
- Checking the empty flag
- Blocking a read when empty

Expected read sequence:

`10, 20, 30, 40`

### 2. Self-Checking SystemVerilog Testbench

The SystemVerilog testbench (`tb_sync_fifo_sv.sv`) extends verification with:

- **Reference-model scoreboard:** Maintains an expected FIFO queue and compares expected and actual read data.
- **Randomized stimulus:** Exercises different read and write enable combinations.
- **Procedural assertion-style checks:** Checks safety properties, including full/empty consistency, occupancy bounds, and pointer stability during blocked operations.
- **Functional coverage counters:** Tracks occupancy levels, blocked reads and writes, simultaneous read/write requests, and pointer wraparound.
- **Waveform generation:** Generates a VCD file for inspection with GTKWave.

### SystemVerilog Test Results

The reported simulation completed with the following results:

| Metric | Result |
|---|---:|
| Clock cycles | 517 |
| Read-data checks | 244 |
| Assertion checks | 515 |
| Reported errors | 0 |
| Occupancy 0 coverage hits | 69 |
| Occupancy 1 coverage hits | 144 |
| Occupancy 2 coverage hits | 147 |
| Occupancy 3 coverage hits | 114 |
| Occupancy 4 coverage hits | 43 |
| Blocked writes | 20 |
| Blocked reads | 31 |
| Simultaneous read/write requests | 130 |
| Write pointer wraps | 61 |
| Read pointer wraps | 61 |

**Result:** All scoreboard checks passed, with zero reported errors in this simulation.

The assertion-style checks are procedural testbench checks rather than native SystemVerilog Assertions (SVA). The functional coverage results are maintained using counters rather than native covergroups.

## Simulation Instructions

### Requirements

- Icarus Verilog
- GTKWave (optional, for waveform inspection)

### Run the Original Verilog Testbench

Compile:

```bash
iverilog -g2012 -o fifo_sim sync_fifo.v tb_sync_fifo.v
```

Run:

```bash
vvp fifo_sim
```

### Run the SystemVerilog Testbench

Compile:

```bash
iverilog -g2012 -Wall -o fifo_sv_sim sync_fifo.v tb_sync_fifo_sv.sv
```

Run:

```bash
vvp fifo_sv_sim
```

The SystemVerilog testbench generates `fifo_sv.vcd`. To inspect its waveform:

```bash
gtkwave fifo_sv.vcd
```

The original testbench's waveform filename is determined by the `$dumpfile` statement in `tb_sync_fifo.v`. If it uses `fifo.vcd`, open it with:

```bash
gtkwave fifo.vcd
```

## Project Files

- `sync_fifo.v` — FIFO RTL design
- `tb_sync_fifo.v` — Original directed Verilog testbench
- `tb_sync_fifo_sv.sv` — Self-checking SystemVerilog testbench
- `.gitignore` — Excludes simulation executables and VCD waveform files from Git tracking

Simulation executables and generated waveforms are created locally and are not intended to be committed to the repository.
