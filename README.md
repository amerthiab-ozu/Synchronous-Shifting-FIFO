# Synchronous Shifting FIFO

<p align="center">
  <img src="https://img.shields.io/badge/Language-Verilog--2001-blue.svg" alt="Verilog-2001">
  <img src="https://img.shields.io/badge/Category-Digital%20Design-green.svg" alt="Digital Design">
  <img src="https://img.shields.io/badge/Type-Educational-orange.svg" alt="Educational">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT License">
</p>

<p align="center">
  <b>A classic synthesizable synchronous FIFO using shifting register architecture in Verilog-2001</b>
</p>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Features](#-features)
- [Interface](#-interface)
- [Parameters](#-parameters)
- [Theory of Operation](#-theory-of-operation)
- [File Structure](#-file-structure)
- [Simulation](#-simulation)
- [Synthesis Notes](#-synthesis-notes)
- [Waveform Examples](#-waveform-examples)
- [Known Limitations](#-known-limitations)
- [References](#-references)
- [Academic Context](#-academic-context)
- [License](#-license)

---

## 🔍 Overview

This project implements a **synchronous shifting FIFO (First-In-First-Out)** buffer using the classic shifting register architecture. Unlike pointer-based circular buffer FIFOs, this design physically shifts all stored data toward the output on every pop operation, maintaining the oldest entry always at position `mem[0]`.

The shifting FIFO architecture is particularly useful for educational purposes as it clearly demonstrates the FIFO principle and provides a straightforward mental model for understanding queue-based data structures in hardware.

### Key Characteristics

| Property | Value |
|----------|-------|
| **Architecture** | Shifting Register Array |
| **Clock Domains** | Single (Synchronous) |
| **Reset Type** | Synchronous, Active-High |
| **Data Output** | Combinational (Always Available) |
| **Simultaneous Push/Pop** | Supported |

---

## 🏗 Architecture

```
                    ┌─────────────────────────────────────────────────────┐
                    │              SHIFTING FIFO MEMORY                   │
                    │                                                     │
   data_in ────────►│  ┌───┐   ┌───┐   ┌───┐   ┌───┐         ┌───┐      │
                    │  │N-1│◄──│N-2│◄──│...│◄──│ 1 │◄────────│ 0 │──────┼──► data_out
                    │  └───┘   └───┘   └───┘   └───┘         └───┘      │
                    │    ▲                                     │         │
                    │    │              ◄── SHIFT ON POP ──    │         │
                    │    │                                     ▼         │
                    │  wptr                              (always mem[0]) │
                    └─────────────────────────────────────────────────────┘
                              │                     │
                              ▼                     ▼
                           ┌─────┐              ┌───────┐
                           │full │              │ empty │
                           └─────┘              └───────┘
```

### Block Diagram

```
                          ┌──────────────────────────────────────┐
                          │          shifting_fifo               │
                          │                                      │
            clk ─────────►│  ┌────────────┐    ┌────────────┐   │
                          │  │ Sequential │    │Combinational│   │
            rst ─────────►│  │   Logic    │◄──►│   Logic    │   │
                          │  │            │    │            │   │
           push ─────────►│  │  - wptr    │    │ - wptr_nxt │   │
                          │  │  - mem[]   │    │ - empty_nxt│   │
            pop ─────────►│  │  - empty   │    │ - full_nxt │   │
                          │  │  - full    │    │ - data_out │   │
        data_in ─────────►│  └────────────┘    └────────────┘   │
       [BW-1:0]           │                                      │
                          │                                      │────► data_out [BW-1:0]
                          │                                      │────► full
                          │                                      │────► empty
                          └──────────────────────────────────────┘
```

---

## ✨ Features

- **Fully Synthesizable**: Clean RTL suitable for ASIC and FPGA implementation
- **Parameterized Design**: Configurable depth (`N`) and data width (`BW`)
- **Simultaneous Push/Pop**: Supports concurrent read and write operations
- **Zero-Latency Read**: Output data always reflects `mem[0]` combinationally
- **Built-in Monitoring**: Debug-friendly `$display` statements for input changes (simulation only)
- **Comprehensive Testbench**: Directed test with pass/fail reporting

---

## 🔌 Interface

### Port Description

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | Input | 1 | System clock (positive edge triggered) |
| `rst` | Input | 1 | Synchronous reset (active-high) |
| `push` | Input | 1 | Push request - writes `data_in` to FIFO |
| `pop` | Input | 1 | Pop request - removes front entry |
| `data_in` | Input | BW | Data to be written on push |
| `data_out` | Output | BW | Front entry data (combinational) |
| `full` | Output | 1 | FIFO full flag (registered) |
| `empty` | Output | 1 | FIFO empty flag (registered) |

### Timing Diagram

```
           ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐
    clk ───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───┘   └───
              │       │       │       │       │       │
    rst ──────┘       │       │       │       │       │
                      │       │       │       │       │
   push ──────────────┼───────┼───────┘       │       │
                      │       │               │       │
data_in ══════════════╪═══════╪═══════════════╪═══════╪═══════════
              XX      │  D0   │      D1       │  XX   │
                      │       │               │       │
  empty ──────────────┼───────┼───────────────┼───────┼───────────
              1       │       │       0       │       │
                      │       │               │       │
data_out═════════════════════════════════════════════════════════
              XX            D0              D0
```

---

## ⚙ Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `N` | 32 | Number of FIFO entries (buffer depth) |
| `BW` | 8 | Bit width of each data entry |

### Derived Parameters

| Parameter | Formula | Description |
|-----------|---------|-------------|
| `WPW` | `$clog2(N)` | Write pointer width (auto-calculated) |

### Example Instantiation

```verilog
shifting_fifo #(
    .N  (16),       // 16-entry deep FIFO
    .BW (32)        // 32-bit data width
) u_fifo (
    .clk      (clk),
    .rst      (rst),
    .push     (wr_en),
    .pop      (rd_en),
    .data_in  (wr_data),
    .data_out (rd_data),
    .full     (fifo_full),
    .empty    (fifo_empty)
);
```

---

## 📖 Theory of Operation

### Push Operation

When `push` is asserted (and FIFO is not full):
1. `data_in` is written to `mem[wptr_shifted]`
2. Write pointer increments: `wptr_nxt = wptr + 1`
3. `empty` flag clears
4. If FIFO becomes full, `full` flag sets

### Pop Operation

When `pop` is asserted (and FIFO is not empty):
1. All entries shift down: `mem[i] <= mem[i+1]` for i = 0 to N-2
2. Write pointer decrements: `wptr_shifted = wptr - 1`
3. `full` flag clears
4. If FIFO becomes empty, `empty` flag sets

### Simultaneous Push and Pop

When both `push` and `pop` are asserted:
1. Shift operation occurs (data moves toward `mem[0]`)
2. New data written to `mem[wptr-1]` (adjusted position)
3. Write pointer remains unchanged: `wptr_nxt = wptr - 1 + 1 = wptr`
4. Flags remain unchanged (FIFO occupancy stays the same)

### State Transitions

```
                    ┌─────────┐
         reset      │  EMPTY  │◄────────────────┐
        ─────────►  │ wptr=0  │                 │
                    │empty=1  │                 │ pop (when count=1)
                    └────┬────┘                 │
                         │                      │
                         │ push                 │
                         ▼                      │
                    ┌─────────┐                 │
                    │ PARTIAL │─────────────────┤
                    │0<wptr<N │                 │
                    │         │◄────────────────┤
                    └────┬────┘                 │
                         │                      │
                         │ push (when count=N-1)│
                         ▼                      │
                    ┌─────────┐                 │
                    │  FULL   │                 │
                    │ wptr=N  │─────────────────┘
                    │ full=1  │     pop
                    └─────────┘
```

---

## 📁 File Structure

```
Synchronous-Shifting-FIFO/
├── README.md               # This documentation
├── shifting_fifo.v         # RTL source - synthesizable FIFO module
└── tb_shifting_fifo.v      # Testbench with directed tests
```

---

## 🧪 Simulation

### Prerequisites

- **Icarus Verilog** (iverilog) or any Verilog-2001 compatible simulator
- **GTKWave** (optional, for waveform viewing)

### Running the Testbench

```bash
# Compile
iverilog -g2001 -o sim_fifo shifting_fifo.v tb_shifting_fifo.v

# Run
vvp sim_fifo

# View waveforms (if $dumpfile is enabled in testbench)
gtkwave dump.vcd &
```

### Expected Output

```
================================================================================================
FIFO TESTBENCH STARTED (Simplified Directed Tests)
N = 8 | BW = 8 | Clock = 10 ns | Sample = Posedge + 2 ns
Tests: [1] Full Fill  [2] Full Drain  [3] 5x Simultaneous Push/Pop While Full
================================================================================================

------------------------------------------------------------------------------------------------
1) Full Fill
------------------------------------------------------------------------------------------------
[1   ] | [t=32 ns] | (i) | FIFO Is Empty After Reset (Good Start).
[2   ] | [t=32 ns] | (i) | FIFO Is Not Full After Reset.
...
------------------------------------------------------------------------------------------------
Fill Summary | Checks = 12 | Pass = 12 | Fail = 0
------------------------------------------------------------------------------------------------

...

================================================================================================
Testbench Finished | Checks = 57 | Pass = 57 | Fail = 0
Final Result: Pass
================================================================================================
```

### Test Sections

| Section | Description | Checks |
|---------|-------------|--------|
| **1) Full Fill** | Reset → Fill FIFO completely | Empty/Full flag transitions, push operations |
| **2) Full Drain** | Drain FIFO completely → Empty | Data ordering (FIFO behavior), flag transitions |
| **3) Simultaneous Push/Pop** | Push and Pop together while full | Flag stability, data integrity |

---

## 🔧 Synthesis Notes

### Resource Estimates

For a typical FPGA implementation with `N=32` and `BW=8`:

| Resource | Approximate Usage |
|----------|-------------------|
| Flip-Flops | ~260 (32×8 for memory + flags + pointer) |
| LUTs | ~300-400 (shifting logic, muxing) |
| BRAM | 0 (uses distributed RAM / FFs) |

### Timing Considerations

⚠️ **Critical Path Warning**: The shifting operation creates a combinational path through all N memory locations. For large N values, this may limit maximum clock frequency.

**Recommendations**:
- For high-speed applications with large depths, consider a **circular buffer FIFO** instead
- For small depths (N ≤ 16), shifting FIFO performs well
- Pipeline the shift operation if necessary

### Clock Domain

This is a **single clock domain** design. For cross-clock-domain applications, use an asynchronous FIFO architecture with Gray code pointers.

---

## 📊 Waveform Examples

### Basic Push/Pop Sequence

```
Time:     0    10   20   30   40   50   60   70   80   90  100
          │    │    │    │    │    │    │    │    │    │    │
clk:      _/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\
rst:      ‾‾‾‾\____________________________________
push:     ________/‾‾‾‾\____/‾‾‾‾\________________
pop:      ____________________________/‾‾‾‾\______
data_in:  XXXX|  A  |XXXX|  B  |XXXXXXXXXXXXXXXX
data_out: XXXX|XXXXX|  A |  A  |  A  |  B  |XXXX
empty:    ‾‾‾‾‾‾‾‾‾‾\__________________________/‾‾
full:     ____________________________________
wptr:       0 |  0  |  1 |  1  |  2  |  1  |  0
```

---

## ⚠ Known Limitations

1. **Shift Latency**: On pop, all entries must shift, creating O(N) logic depth
2. **Power Consumption**: Higher dynamic power due to shifting all registers
3. **Not Suitable for Large Depths**: Recommended N ≤ 32 for timing closure
4. **Single Clock Only**: No built-in CDC support
5. **No Underflow/Overflow Protection**: User must check `empty`/`full` flags

---

## 📚 References

1. Cummings, Clifford E. "Simulation and Synthesis Techniques for Asynchronous FIFO Design." SNUG 2002.
2. Pong P. Chu, "FPGA Prototyping by Verilog Examples," Wiley, 2008.
3. IEEE Standard 1364-2001 (Verilog-2001)

---

## 🎓 Academic Context

<table>
<tr>
<td><b>Institution</b></td>
<td>Özyeğin University</td>
</tr>
<tr>
<td><b>Department</b></td>
<td>Electrical and Electronics Engineering</td>
</tr>
<tr>
<td><b>Course</b></td>
<td>EE568 - Hardware Design Patterns</td>
</tr>
<tr>
<td><b>Instructor</b></td>
<td>Prof. H. Fatih Uğurdağ</td>
</tr>
<tr>
<td><b>Teaching Assistant</b></td>
<td>Amer Dyab (<a href="mailto:amer.thiab@ozu.edu.tr">amer.thiab@ozu.edu.tr</a>)</td>
</tr>
</table>

---

## 📄 License

This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2025 Özyeğin University - EE568 Hardware Design Patterns

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<p align="center">
  <b>Repository:</b> <a href="https://github.com/amerthiab-ozu/Synchronous-Shifting-FIFO">github.com/amerthiab-ozu/Synchronous-Shifting-FIFO</a>
</p>

<p align="center">
  <i>Developed as part of EE568 Hardware Design Patterns at Özyeğin University</i>
</p>
