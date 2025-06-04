# Digital-CIM

## Overview
This project hosts Verilog implementations and explorations of Digital Compute-In-Memory (CIM) architectures. It includes different modules that demonstrate CIM operations and array structures.

## Implementations

The repository contains multiple areas of work or implementations:

### 1. `ourwork/` Implementation
This directory contains a Verilog-based CIM design.

**Key Modules:**
*   `ourwork/top.v`: The top-level module that integrates the CIM array and processing units.
*   `ourwork/local_mac.v`: Performs local multiply-accumulate operations.
    *   **New Feature (FMAS):** This module now supports a Fused Multiply-Add-Subtract (FMAS) operation in addition to a standard MAC operation.
        *   **Operation Selection (`op_sel` input):**
            *   `op_sel = 0`: MAC operation (`Result = (A*B) + C_in`)
            *   `op_sel = 1`: FMAS operation (`Result = (A*B) + C_in - D_in`)
        *   **New Inputs:** `C_in[11:0]` and `D_in[11:0]` for the add/subtract components.
        *   **Output:** `result_out[13:0]` provides the outcome of the selected operation.
*   `ourwork/cim_array.v`: Represents the memory array designed with in-memory computing capabilities.
*   `ourwork/cim_bank.v`: A fundamental building block of the `cim_array`.

**Testing:**
*   A testbench can be found at `ourwork/test/top_tb.v` which demonstrates how to stimulate the `top.v` module and observe its behavior, including the new FMAS functionality.

### 2. `tsmc2023/` Implementation
This directory contains another Verilog-based CIM design, potentially related to a TSMC 2023 project or technology.

**Documentation:**
*   Detailed documentation for this specific architecture can be found in the file named `电路复现架构——tsmc2023.md`.
    *   **Note:** This filename contains Chinese characters and an em-dash. Some tools or systems might have difficulty processing this filename directly. Please ensure your environment supports UTF-8 filenames or consider renaming it locally if you encounter issues.

## General Guidance for Simulation
To simulate these designs:
1.  Navigate to the relevant implementation directory (e.g., `ourwork/`).
2.  Use a standard Verilog simulator (e.g., ModelSim, Icarus Verilog, Verilator, Xcelium, Vivado Simulator).
3.  Compile the necessary Verilog files, including the testbench (e.g., `ourwork/test/top_tb.v`).
4.  Run the simulation and observe outputs (e.g., VCD waveform files or console logs from `$display` statements). The testbenches typically include example stimuli.

## Contributing
(Placeholder for contribution guidelines - if any)
