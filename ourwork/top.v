// top: Top-level module for the Digital Compute-In-Memory (CIM) architecture.
// Integrates CIM arrays, local MAC/FMAS units, and global control/IO.
module top(
    // Original inputs
    input [23:0] D,               // Data input, primarily for CIM array programming
    input clk,rstn,cima,acm_en,   // Clock, reset, CIM array control, accumulator enable
    input [7:0] WA,               // Write address for CIM array
    input inwidth,                // Input width control for gctrl -> sel signal width
    input wwidth,                 // Write width control, used in local_mac lmacb's sus and global_io
    input [95:0] xin0,            // Input data for rwldrv, influences local_mac control signals

    // New top-level inputs for FMAS functionality, passed to local_mac instances
    input wire [11:0] C_in,       // Addend for local_mac units (MAC/FMAS operations)
    input wire [11:0] D_in,       // Subtrahend for local_mac units (FMAS operation only)
    input wire op_sel,          // Operation select for local_mac units: 0 for MAC, 1 for FMAS

    // Original outputs
    output [50:0] nout,           // Final output of the CIM processing
    output wire st                // Status signal from gctrl
);
    // Wires connecting sub-modules
    wire [13:0] macout_a,macout_b; // Output from local_mac units (lmaca, lmacb)
                                  // Adjusted width from [14:0] to [13:0] to match local_mac.result_out
    wire [95:0] wb0_a,wb1_a,wb0_b,wb1_b; // Data wires from CIM array to local_mac units
    wire [7:0] rwlb_row1,rwlb_row0;     // Control signals from rwldrv to local_mac units
    wire [5:0] sel;                     // Select signal from gctrl to rwldrv
    wire [23:0] D1;                     // Data output from cim_array_ctrl to cim_array
    wire [7:0] WA0, WA1;                // Write address outputs from cim_array_ctrl to cim_array

    // Instantiate global_io: handles final output accumulation and formatting
    global_io global_io_u(
        .macout_a(macout_a),
        .macout_b(macout_b),
        .clk(clk),
        .acm_en(acm_en),
        .rstn(rstn),
        .st(st),
        .wwidth(wwidth),
        .nout(nout)
    );

    // Instantiate cim_array_ctrl: controls the CIM array operations
    cim_array_ctrl cim_array_ctrl_u(
        .D(D),
        .WA(WA),
        .clk(clk),
        .rstn(rstn),
        .cima(cima),
        .D1(D1),
        .WA0(WA0),
        .WA1(WA1)
    );

    // Instantiate cim_array: the main compute-in-memory array
    cim_array cim_array_u(
        .D1(D1),
        .WA0(WA0),
        .WA1(WA1),
        .wb0_a(wb0_a),
        .wb1_a(wb1_a),
        .wb0_b(wb0_b),
        .wb1_b(wb1_b)
    );

    // Instantiate lmaca: local_mac unit A
    local_mac lmaca(
        .wb0(wb0_a),             // Data input from cim_array
        .wb1(wb1_a),             // Data input from cim_array
        .rwlb_row1(rwlb_row1),   // Control signal from rwldrv
        .rwlb_row0(rwlb_row0),   // Control signal from rwldrv
        .C_in(C_in),             // Connect top-level C_in for MAC/FMAS
        .D_in(D_in),             // Connect top-level D_in for FMAS
        .op_sel(op_sel),         // Connect top-level op_sel for operation selection
        .sus(1'b0),              // sus signal (fixed for lmaca)
        .result_out(macout_a)    // Output connected to macout_a (renamed from mac_out)
    );

    // Instantiate lmacb: local_mac unit B
    local_mac lmacb(
        .wb0(wb0_b),             // Data input from cim_array
        .wb1(wb1_b),             // Data input from cim_array
        .rwlb_row1(rwlb_row1),   // Control signal from rwldrv
        .rwlb_row0(rwlb_row0),   // Control signal from rwldrv
        .C_in(C_in),             // Connect top-level C_in for MAC/FMAS
        .D_in(D_in),             // Connect top-level D_in for FMAS
        .op_sel(op_sel),         // Connect top-level op_sel for operation selection
        .sus(~wwidth),           // sus signal (dependent on wwidth for lmacb)
        .result_out(macout_b)    // Output connected to macout_b (renamed from mac_out)
    );

    // Instantiate rwldrv: row/word line driver logic
    rwldrv rwldrv_u(
        .cima(cima),
        .xin(xin0),
        .clk(clk),
        .rstn(rstn),
        .sel(sel),
        .rwlb_row1(rwlb_row1),
        .rwlb_row0(rwlb_row0)
    );

    // Instantiate gctrl: global control logic
    gctrl gctrl_u(
        .inwidth(inwidth),
        .clk(clk),
        .rstn(rstn),
        .sel(sel),
        .st(st)
    );

endmodule
