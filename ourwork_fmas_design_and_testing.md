```markdown
# FMAS Feature in `ourwork` Directory

This document describes the Fused Multiply-Add-Subtract (FMAS) feature and related modifications implemented in the Verilog modules within the `ourwork/` directory, and how they are tested.

## Feature Overview

A new selectable operation was added to the `local_mac` module:
- **Modified MAC**: `Result = (A*B) + C`
- **Fused Multiply-Add-Subtract (FMAS)**: `Result = (A*B) + C - D`

The `(A*B)` term represents the existing sum-of-products calculation performed by the `local_mac` module using its `oai_mult` instances and adder tree. The inputs `A` and `B` for these multiplications are typically derived from the outputs of the CIM (Compute-In-Memory) banks (`wb0_sig` and `wb1_sig` arrays, where each element is 12-bit).

A 1-bit control signal `op_sel` selects the operation:
- `op_sel = 0`: Selects Modified MAC operation.
- `op_sel = 1`: Selects FMAS operation.

## Module Modifications

### 1. `ourwork/local_mac.v`

- **New Input Ports**:
    - `input wire [11:0] C_in`: Input for the C term in the operations.
    - `input wire [11:0] D_in`: Input for the D term in the FMAS operation.
    - `input wire op_sel`: Operation select signal.

- **Output Port Change**:
    - The output port `mac_out` has been renamed to `result_out`.
    - `output reg [13:0] result_out`: The result of the selected operation. The width is 14 bits. The previous `mac_out` (which represented the `A*B` sum-of-products term) was 15-bit (`[14:0]`). The arithmetic for `(A*B) + C` can result in a 16-bit value (15-bit `A*B` + 12-bit `C`), and `(A*B) + C - D` can also result in a 16-bit value. The final `result_out` takes the lower 14 bits `[13:0]` of these 16-bit intermediate calculations.

- **Functional Logic**:
    - The module calculates `Sum_AB = A*B` (the existing sum of 8 `oai_mult` outputs, resulting in a 15-bit signal `final_adder_sum_signal`).
    - Intermediate calculations `sum_with_C_val = Sum_AB + C_in` and `fmas_val = sum_with_C_val - D_in` are performed using 16-bit wires.
    - If `op_sel == 0`, `result_out = sum_with_C_val[13:0]`.
    - If `op_sel == 1`, `result_out = fmas_val[13:0]`.

### 2. `ourwork/top.v`

- **New Input Ports**:
    - `input wire [11:0] C_in`: Propagated to `local_mac` instances.
    - `input wire [11:0] D_in`: Propagated to `local_mac` instances.
    - `input wire op_sel`: Propagated to `local_mac` instances.

- **Internal Wire Changes**:
    - The wires connecting to the `result_out` ports of the `local_mac` instances (`lmaca` and `lmacb`), named `macout_a` and `macout_b` respectively, have been changed from 15-bit (`[14:0]`) to 14-bit (`[13:0]`) to match the new width of `result_out`.
    - These 14-bit `macout_a` and `macout_b` signals are then zero-extended to 15 bits when passed as inputs to the `global_io` module, to maintain compatibility with `global_io`'s existing 15-bit input port width. No changes were made to `global_io` itself.

## Testing (`ourwork/test/top_tb.v`)

The testbench `ourwork/test/top_tb.v` was significantly modified because it contains inline definitions of all modules (`local_mac`, `top`, `cim_bank`, etc.) rather than including them from source files.

- **Modifications to Inline Modules in Testbench**:
    - The inline Verilog code for `local_mac` within `top_tb.v` was updated to match the changes described above for `ourwork/local_mac.v` (new ports, new logic, `result_out`). Bit widths for intermediate calculations (`final_adder_sum_signal [14:0]`, `sum_with_C_val [15:0]`, `fmas_val [15:0]`) and final truncation to `result_out [13:0]` were implemented.
    - The inline Verilog code for `top` within `top_tb.v` was updated:
        - Added new input ports `C_in`, `D_in`, `op_sel`.
        - Added new output ports `output wire [13:0] mac_res_a, mac_res_b;` to directly observe the 14-bit results from the `local_mac` instances within the `top` module. This was a necessary change to enable the test cases to monitor these specific signals.
        - Internal wires `macout_a`, `macout_b` changed to `[13:0]`.
        - `local_mac` instantiations updated with new port connections.
        - `macout_a` and `macout_b` are zero-extended to 15 bits before being passed to `global_io`.

- **Testbench (`top_tb` module) Updates**:
    - New `reg` declarations for driving the new inputs:
        - `reg [11:0] C_in_tb;`
        - `reg [11:0] D_in_tb;`
        - `reg op_sel_tb;`
    - New `wire` declarations for observing the new `top` outputs:
        - `wire [13:0] mac_res_a_tb;`
        - `wire [13:0] mac_res_b_tb;`
    - The `top_u` instance was updated to connect these new registers and wires.

- **New Test Cases**:
    - Test sequences were added to the `initial` block to verify the new operations:
        1.  **FMAS Operation**:
            - `op_sel_tb` is set to `1'b1`.
            - `C_in_tb` and `D_in_tb` are set to example values (e.g., 10 and 5).
            - `$display` statements show the inputs and the resulting `mac_res_a_tb` and `mac_res_b_tb`.
        2.  **Modified MAC Operation (A*B + C)**:
            - `op_sel_tb` is set to `1'b0`.
            - `C_in_tb` is set to an example value (e.g., 20). `D_in_tb` is also set, but should not affect the result.
            - `$display` statements show the inputs and results.
        3.  **Original MAC-like behavior (A*B)**:
            - `op_sel_tb` is set to `1'b0`.
            - `C_in_tb` is set to `12'd0`.
            - `$display` statements show the inputs and results.

    - The values for `(A*B)` depend on data previously written into the CIM banks by the testbench's memory write sequence and the `xin0` input affecting `rwldrv`. The test results will reflect this. The `$display` statements are crucial for observing the behavior. Minor corrections were also made to the testbench and inline modules for improved stability and correctness (e.g., memory initialization in `cim_bank`, genvar naming, default conditions).
```
