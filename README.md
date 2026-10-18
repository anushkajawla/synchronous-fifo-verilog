# Synchronous FIFO using Verilog

## Project Overview
This project implements a synchronous First-In, First-Out (FIFO) buffer using Verilog HDL. It stores four 8-bit data entries and returns them in the order they were written.

## Features
- 8-bit data width and four storage locations
- Synchronous read and write operations
- Read and write pointers with wraparound
- Full and empty status flags
- Protection against writes when full and reads when empty
- Testbench for functional simulation

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

A counter tracks the number of stored entries. The `full` flag is asserted when the count reaches four, and `empty` is asserted when the count is zero.

The synchronous reset clears the pointers, counter, and output at a rising clock edge when reset is active. Writes are blocked when full, and reads are blocked when empty. If a valid read and write occur together, the counter remains unchanged.

## Simulation Instructions

Compile using Icarus Verilog:

```bash
iverilog -o fifo_sim sync_fifo.v tb_sync_fifo.v
```

Run the simulation:

```bash
vvp fifo_sim
```

The testbench generates `fifo.vcd`. To inspect the waveform using GTKWave:

```bash
gtkwave fifo.vcd
```

## Expected Results
The FIFO reads the values in this order:

`10, 20, 30, 40`

After four writes, `full = 1` and `empty = 0`. After four reads, `full = 0` and `empty = 1`. Additional writes when full and reads when empty are blocked.

## Project Files
- `sync_fifo.v` — FIFO design
- `tb_sync_fifo.v` — simulation testbench
- `fifo.vcd` — generated waveform file
<img width="560" height="290" alt="image" src="https://github.com/user-attachments/assets/8ff2fe09-5da2-47fe-b6ce-e9b35c0cbc08" />
<img width="959" height="448" alt="image" src="https://github.com/user-attachments/assets/f721906f-a7b5-487e-81c2-1b6c76827895" />

