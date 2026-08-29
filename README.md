![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# MC14500B Extended 1-bit Microcontroller SoC

This project transforms the classic 1-bit Motorola MC14500B Industrial Control Unit (ICU) architecture into a complete, independent System on Chip (SoC) optimized for the **TTIHP26b (IHP 130 nm BiCMOS)** shuttle run. Scaled up to a 3x2 tile layout, it moves beyond a simple execution core by integrating memory, hardware counters, and dedicated parallel I/O.

## How It Works

The system operates as an autonomous single-chip computer that continuously loops through its preloaded execution routines as soon as power is applied and the reset sequence completes.

### Structural SoC Specifications:
* **Core CPU:** 1-bit Motorola MC14500B Industrial Control Unit matching the classic 16-opcode Instruction Set Architecture (ISA).
* **Program Counter (PC):** Integrated 8-bit sequential stepping address register.
* **On-Chip ROM Program Memory:** 256 Words x 8-bit instruction bus width. Opcodes are mapped to the upper nibble (`[7:4]`), while memory addresses map to the lower nibble (`[3:0]`).
* **On-Chip Data RAM Scratchpad:** 16 independent single-bit memory registers (`4'h0` to `4'hF`).

### I/O Data Map Allocation:
* **Parallel Inputs (`ui_in`):** Synced automatically into RAM cells `[15:8]` on every clock edge.
* **Parallel Outputs (`uo_out`):** Driven continuously by the contents of RAM cells `[7:0]`.
* **Diagnostic Monitors (`uio_out`):** Exposes the 6 low-order PC bits, the core Result Register (`RR`), and the internal RAM write strobe pulse directly to physical pins for real-time trace analysis.

## How to Test

You can test the design via behavioral RTL simulations, gate-level netlists, or directly on the physical hardware breakout board.

### 1. Verification via Simulation (cocotb)
The integrated test suite uses a Python-driven `cocotb` test harness to evaluate your design pipeline.

* **Navigate to the test directory:**
  ```bash
  cd test
  ```
* **Execute the simulation verification loop:**
  ```bash
  make
  ```
The testbench sets up a 50 MHz simulation clock, executes a hardware reset, streams static test pattern bits into the dedicated input pins, and verifies that the parallel outputs and program counter cycles match the preloaded ROM instruction routine.

### 2. Manual Testing on Hardware
* **Reset Sequence:** Pull `rst_n` low, apply a stable clock to `clk`, then pull `rst_n` high.
* **Observe Execution:** Toggle the input pins on the `ui_in` bus. Watch the `uo_out` pins change state as the internal MCU loops through its ROM program, performs bitwise calculations, and updates the output data bank.

---
For more information regarding Tiny Tapeout development workflows, visit the official resource links below:

* [Tiny Tapeout FAQ & Troubleshooting Guide](https://tinytapeout.com)
* [Learn how semiconductors work with SiliWiz](https://tinytapeout.com)
* [Join the Tiny Tapeout Community Discord](https://tinytapeout.com)
