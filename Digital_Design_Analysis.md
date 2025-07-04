# 数字电路设计文档：CIM-PQC 加速器

## 1. 项目概述

本项目是基于**存算一体 (Compute-in-Memory, CIM)** 架构的**后量子密码 (Post-Quantum Cryptography, PQC)** 加速器的数字逻辑设计部分。

整体目标是利用 Verilog HDL 设计一个高效的硬件加速器。代码库 (`ourwork/` 目录) 包含了一个分层设计的数字电路，从底层的算术逻辑单元到顶层的系统控制器，并配备了相应的仿真测试平台。

## 2. 模块架构与功能分析

数字部分的 Verilog 代码采用模块化设计，层次清晰。核心模块及其功能如下：

### 顶层模块

-   **`top.v`**: 设计的最高层级，负责例化并连接所有的核心子模块，如全局控制器、存算库 (`cim_bank`) 和全局IO等，构成完整的加速器数据通路和控制流。
-   **`top_tb.v`**: 顶层测试平台 (Testbench)。该文件是进行仿真验证的入口，其核心作用是：
    1.  例化 `top.v` 模块。
    2.  产生时钟 (`clk`) 和复位 (`rst_n`) 信号。
    3.  模拟外部输入，为 `top` 模块提供激励信号。
    4.  通过 `$dumpfile` 和 `$dumpvars` 系统任务，生成用于波形分析的 `top_tb.vcd` 文件。
    5.  **注意**: 该文件很可能通过 `` `include `` 预处理指令包含了所有其他必要的 `.v` 设计文件，因此在编译时只需指定该文件即可。

### 控制模块

-   **`gctrl.v` (Global Controller)**: 全局控制器。这是整个设计的“大脑”，负责解析指令、生成控制时序，并协调各个子模块（如 `cim_array_ctrl` 和数据通路模块）的协同工作。
-   **`cim_array_ctrl.v`**: 存算阵列控制器。接收来自 `gctrl` 的高层指令，并生成对 `cim_array` 进行读、写和计算操作所需的精确控制信号（如片选、行地址、读写使能等）。

### 核心计算与存储模块

-   **`cim_bank.v`**: 存算库。一个更高层级的存储和计算单元，通常由多个 `cim_array` 组成，以扩大存储容量和并行计算能力。
-   **`cim_array.v`**: 存算阵列。项目的核心，是执行存内计算和数据存储的基本单元。它由大量的SRAM单元或其他存算单元构成。

### 数据通路与算术逻辑单元 (ALU)

-   **`global_io.v`**: 全局输入/输出模块，负责管理数据在芯片内外的传输。
-   **`accumulator.v`**: 累加器，用于对计算结果进行累加操作。
-   **`add.v` / `s_cla.v` / `se_cla.v`**: 不同结构和性能的加法器。`cla` 代表先行进位加法器 (Carry-Lookahead Adder)，是一种高速加法器。
-   **`local_mac.v`**: 局部乘加单元 (Multiply-Accumulate)，可能用于执行小规模的乘加运算。
-   **`oai_mult.v`**: 可能是使用 OAI (OR-AND-Invert) 逻辑门实现的乘法器。
-   **`rwldrv.v`**: 行/字线驱动器 (Row/Word-Line Driver)，用于在阵列中选择特定的行。

## 3. 仿真与测试

使用 `iverilog` 和 `vvp` 工具可以对设计进行编译和仿真。

### 仿真命令

在项目根目录 `Digital-CIM/` 下执行以下命令：

```bash
# 1. 编译 Verilog 文件并指定输出文件
iverilog -o ./ourwork/test/top_tb.out ./ourwork/test/top_tb.v

# 2. 运行仿真
vvp ./ourwork/test/top_tb.out
```

**合并后的一行命令：**

```bash
iverilog -o ./ourwork/test/top_tb.out ./ourwork/test/top_tb.v && vvp ./ourwork/test/top_tb.out
```

### 命令解析

1.  **`iverilog -o ./ourwork/test/top_tb.out ./ourwork/test/top_tb.v`**
    -   `iverilog`: 调用 Icarus Verilog 编译器。
    -   `-o ./ourwork/test/top_tb.out`: 指定编译后生成的仿真可执行文件的路径和名称。
    -   `./ourwork/test/top_tb.v`: 指定需要编译的顶层测试平台文件。如前所述，该文件内部已包含所有设计文件，因此无需列出其他 `.v` 文件，避免了模块重复定义的错误。

2.  **`vvp ./ourwork/test/top_tb.out`**
    -   `vvp`: 调用 `iverilog` 的运行时引擎，执行编译好的仿真文件。

### 结果分析

-   **控制台输出**: 成功运行后，您将在控制台看到仿真过程中的信息，例如 `VCD info: dumpfile top_tb.vcd opened for output.`，并最终以 `$finish` 任务结束仿真。
-   **波形文件**: 仿真会在 `ourwork/test/` 目录下生成一个名为 `top_tb.vcd` 的波形文件。您可以使用 **GTKWave** 或其他波形查看工具打开此文件，以图形化方式查看所有信号在仿真过程中的跳变，从而验证设计的逻辑功能是否符合预期。

## 4. 总结

当前数字部分的设计已经相当完善，具备了清晰的层次结构和完整的仿真验证环境。下一步的工作可以聚焦于：

-   **功能验证**: 深入分析 `top_tb.vcd` 波形，确保在各种输入激励下，设计的输出都符合 PQC 算法的要求。
-   **逻辑综合**: 使用 `tcl/` 目录下的脚本，将 Verilog RTL 代码转换为门级网表，为后续的物理实现做准备。
