# Simulation Guide for `tsmc2023/` Design

## Introduction
This guide provides instructions on how to simulate the Verilog design located in the `tsmc2023/` directory, specifically focusing on the `top.v` module and its testbench `top_tb.v`.

## Design Overview
The main files for this simulation are:
*   `tsmc2023/top_tb.v`: The testbench for the `top` module.
*   `tsmc2023/top.v`: The top-level Verilog module for the design. (Definition is also included within `top_tb.v`)

**Important Note on File Structure:**
The testbench file `tsmc2023/top_tb.v` is self-contained. It includes the Verilog code for the `top` module and all its necessary submodules (`global_io`, `cim_array`, `local_mac`, `rwldrv`, `gctrl`, `accumulator`, `se_cla`, `add`, `s_cla`, and `oai_mult`). This simplifies the compilation process as you typically only need to compile `top_tb.v`.

If you intend to simulate `top.v` using individual module files, you would need to compile `top.v` along with all the aforementioned submodules located in the `tsmc2023/` directory. However, for ease of use with the provided testbench, using `top_tb.v` directly is recommended.

## Simulating with Icarus Verilog (Example)

Icarus Verilog is a free and open-source Verilog simulator. If you have it installed, you can follow these steps:

1.  **Open your terminal or command prompt.**
2.  **Navigate to the `tsmc2023/` directory** of this project.
    ```bash
    cd path/to/your/project/tsmc2023/
    ```
3.  **Compile the testbench:**
    Since `top_tb.v` is self-contained, you only need to specify it for compilation.
    ```bash
    iverilog -o top_tb_sim top_tb.v
    ```
    This command compiles `top_tb.v` and creates an executable simulation file named `top_tb_sim`.
4.  **Run the simulation:**
    ```bash
    vvp top_tb_sim
    ```
    This will execute the simulation. The testbench is configured to run for 500ns and generate a VCD (Value Change Dump) file.
5.  **Output:**
    *   A file named `top_tb.vcd` will be generated in the `tsmc2023/` directory. This file contains the waveform data.
    *   Any `$display` messages from the testbench will appear in your terminal.

## Simulating with Other Simulators (General Guidance)

If you are using other Verilog simulators such as ModelSim/QuestaSim, Xcelium, Vivado Simulator, Synopsys VCS, etc., the general steps are similar, but the commands will differ:

1.  **Set up your simulator environment.** (Ensure licenses are available, paths are set, etc.)
2.  **Create a project or use command-line compilation.**
3.  **Compile `tsmc2023/top_tb.v`.** As it's self-contained, this should be the primary (or only) Verilog file you need to add to your compilation list for this specific testbench.
    *   Consult your simulator's documentation for the exact compilation commands (e.g., `vlog` for ModelSim/Questa, `xmvlog` for Xcelium, etc.).
4.  **Run the simulation.**
    *   Specify `top_tb` as the top-level simulation module.
    *   Launch the simulation (e.g., `vsim` for ModelSim/Questa, `xmsim` for Xcelium).
5.  **Observe Outputs:**
    *   The simulation will generate `top_tb.vcd` (as specified by `$dumpfile` in the testbench).
    *   Review console messages and any GUI waveform windows provided by your simulator.

## Viewing Waveforms

The `top_tb.vcd` file can be viewed with a waveform viewer program to analyze the signals over time.
*   **GTKWave:** A popular free and open-source VCD waveform viewer available for Linux, Windows, and macOS.
    ```bash
    gtkwave top_tb.vcd
    ```
*   Most commercial simulators also have built-in waveform viewers.

## Modifying the Simulation
You can modify `tsmc2023/top_tb.v` to:
*   Change the simulation duration (adjust the `#500 $finish;` line).
*   Alter the input stimuli in the `initial` block to test different scenarios.
*   Add more `$display` statements for debugging.

Remember to recompile after making changes to the Verilog code.
