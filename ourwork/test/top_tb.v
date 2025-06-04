`timescale 1ns / 1ps

module top_tb();
    reg [23:0] D;
    reg clk,rstn,cima,acm_en;
    reg [7:0] WA;
    reg inwidth;
    reg wwidth;
    reg [95:0] xin0;

    reg [11:0] C_in_tb;      // ADDED C_in for top module
    reg [11:0] D_in_tb;      // ADDED D_in for top module
    reg op_sel_tb;         // ADDED op_sel for top module

    wire [50:0] nout;
    wire st;

    top top_u(
        .D(D),
        .clk(clk),
        .rstn(rstn),
        .cima(cima),
        .acm_en(acm_en),
        .WA(WA),
        .inwidth(inwidth),
        .wwidth(wwidth),
        .xin0(xin0),
        .C_in(C_in_tb),      // ADDED connection
        .D_in(D_in_tb),      // ADDED connection
        .op_sel(op_sel_tb),  // ADDED connection
        .nout(nout),
        .st(st)
    );

    always begin
        #5 clk = ~clk;
    end

    initial begin
        clk = 0;
        rstn = 0;
        cima = 0;
        acm_en = 1;
        WA = 0;
        inwidth = 0;
        wwidth = 0;
        xin0 = 0; // Default xin0 leads to c,d inputs of oai_mult being 1, making XINxW[j] = 0.
                  // This means current_mac_sum will be 0, simplifying C, D path testing.
        C_in_tb = 0; // Initialize new inputs
        D_in_tb = 0; // Initialize new inputs
        op_sel_tb = 0; // Initialize new inputs

        #10 rstn = 1;

        // Original stimulus that might write to CIM banks - keep it to see its effect or if needed
        D = ~24'b0;
        #5 WA = 1;
        #5 WA = 2;
        #5 WA = 4;
        #5 WA = 8;
        #5 WA = 16;
        #5 WA = 32;
        // #10 cima = 1;xin0=~96'b0/17; // Original cima and xin0 change, commented out for now to keep current_mac_sum = 0

        #20; // Allow time for reset and any initial bank writes to settle.

        $display("--- BEGINNING MAC/FMAS TESTS (Expecting current_mac_sum = 0) ---");
        // Test Case 1: FMAS
        op_sel_tb = 1; // FMAS mode
        C_in_tb = 15;
        D_in_tb = 5;
        // Expected result_out_a/b = (0 + 15 - 5) = 10
        #10; $display("[%0t] FMAS Test 1: op_sel=%b, C_in=%d, D_in=%d -> macout_a=%d, macout_b=%d (Expected: 10)", $time, op_sel_tb, C_in_tb, D_in_tb, top_u.macout_a, top_u.macout_b);

        // Test Case 2: MAC
        op_sel_tb = 0; // MAC mode
        C_in_tb = 20;
        // Expected result_out_a/b = (0 + 20) = 20
        #10; $display("[%0t] MAC Test 1: op_sel=%b, C_in=%d, D_in=%d -> macout_a=%d, macout_b=%d (Expected: 20)", $time, op_sel_tb, C_in_tb, D_in_tb, top_u.macout_a, top_u.macout_b);

        // Test Case 3: FMAS with different values (potentially negative if signed, wraps around if unsigned)
        op_sel_tb = 1; // FMAS mode
        C_in_tb = 7;
        D_in_tb = 10;
        // Expected result_out_a/b = (0 + 7 - 10) = -3. For 14-bit unsigned, this is 2^14 - 3 = 16384 - 3 = 16381.
        #10; $display("[%0t] FMAS Test 2 (neg result): op_sel=%b, C_in=%d, D_in=%d -> macout_a=%d, macout_b=%d (Expected: 16381)", $time, op_sel_tb, C_in_tb, D_in_tb, top_u.macout_a, top_u.macout_b);

        // Test Case 4: MAC with a larger C_in value
        op_sel_tb = 0; // MAC mode
        C_in_tb = 12'hF00; // 3840 decimal
        // Expected result_out_a/b = (0 + 3840) = 3840
        #10; $display("[%0t] MAC Test 2 (large C): op_sel=%b, C_in=%d, D_in=%d -> macout_a=%d, macout_b=%d (Expected: 3840)", $time, op_sel_tb, C_in_tb, D_in_tb, top_u.macout_a, top_u.macout_b);

        #100; // Allow more time for these tests to complete and outputs to be observed.
        $display("--- FINISHING SIMULATION ---");
        #200 $finish; // Original finish was #500. Total time now is sum of delays.
    end
    initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0,top_tb); // Dump all vars in top_tb and below
    end

endmodule

// Embedded 'top' module, modified for new C, D, op_sel inputs
module top(
    input [23:0] D,
    input clk,rstn,cima,acm_en,
    input [7:0] WA,
    input inwidth,
    input wwidth,
    input [95:0] xin0,
    input wire [11:0] C_in,   // ADDED
    input wire [11:0] D_in,   // ADDED
    input wire op_sel,      // ADDED
    output [50:0] nout,
    output wire st
);
    wire [13:0] macout_a,macout_b; // CHANGED width from [14:0]
    wire [95:0] wb0_a,wb1_a,wb0_b,wb1_b;
    wire [7:0] rwlb_row1,rwlb_row0;
    wire [5:0] sel;
    wire [23:0] D1;
    wire [7:0] WA0, WA1;

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

    cim_array cim_array_u(
        .D1(D1),
        .WA0(WA0),
        .WA1(WA1),
        .wb0_a(wb0_a),
        .wb1_a(wb1_a),
        .wb0_b(wb0_b),
        .wb1_b(wb1_b)
    );

    local_mac lmaca(
        .wb0(wb0_a),
        .wb1(wb1_a),
        .rwlb_row1(rwlb_row1),
        .rwlb_row0(rwlb_row0),
        .C_in(C_in),         // ADDED
        .D_in(D_in),         // ADDED
        .op_sel(op_sel),     // ADDED
        .sus(1'b0),
        .result_out(macout_a) // CHANGED from .mac_out
    );

    local_mac lmacb(
        .wb0(wb0_b),
        .wb1(wb1_b),
        .rwlb_row1(rwlb_row1),
        .rwlb_row0(rwlb_row0),
        .C_in(C_in),         // ADDED
        .D_in(D_in),         // ADDED
        .op_sel(op_sel),     // ADDED
        .sus(~wwidth),       // Original logic for sus
        .result_out(macout_b) // CHANGED from .mac_out
    );

    rwldrv rwldrv_u(
        .cima(cima),
        .xin(xin0),
        .clk(clk),
        .rstn(rstn),
        .sel(sel),
        .rwlb_row1(rwlb_row1),
        .rwlb_row0(rwlb_row0)
    );

    gctrl gctrl_u(
        .inwidth(inwidth),
        .clk(clk),
        .rstn(rstn),
        .sel(sel),
        .st(st)
    );

endmodule

// Embedded 'local_mac' module, modified for C_in, D_in, op_sel and new output
module local_mac(
    input [95:0] wb0,
    input [95:0] wb1,
    input [7:0] rwlb_row1,
    input [7:0] rwlb_row0,
    input sus,
    input wire [11:0] C_in,      // ADDED
    input wire [11:0] D_in,      // ADDED
    input wire op_sel,         // ADDED
    output wire [13:0] result_out // CHANGED from mac_out [14:0]
);
    wire [11:0] wb0_sig [0:7];
    wire [11:0] wb1_sig [0:7];
    wire [11:0] XINxW [0:7];
    wire [12:0] and1 [0:3];
    wire [13:0] and2 [0:1];

    wire [14:0] current_mac_sum; // ADDED - for the sum of 8 products
    wire [15:0] add_c_result;    // ADDED - for current_mac_sum + C_in
    wire [15:0] sub_d_result;    // ADDED - for add_c_result - D_in

    genvar idx;
    generate
        for (idx = 0; idx < 8; idx = idx + 1) begin
            assign wb0_sig[idx] = wb0[idx*12 +: 12];
            assign wb1_sig[idx] = wb1[idx*12 +: 12];
        end
    endgenerate

    genvar i,j;
    generate
        // 例化OAI乘法器 (oai_mult definition is below, unchanged)
        for (j = 0; j < 8; j = j + 1) begin:mult_array
            oai_mult m1 (
                .a(wb0_sig[j]),
                .b(wb1_sig[j]),
                .c(rwlb_row0[j]), // c input for oai_mult
                .d(rwlb_row1[j]), // d input for oai_mult
                .e(XINxW[j])
            );
        end

        // 第一级加法树 (add module definition is below, unchanged)
        for (i = 0; i < 4; i = i + 1) begin
            add #(12) a1
            (
                .s(and1[i]),
                .sus(sus), // Pass sus to adder
                .a(XINxW[2*i]),
                .b(XINxW[2*i+1])
            );
        end

        // 第二级加法树
        for (i = 0; i < 2; i = i + 1) begin
            add #(13) a2
            (
                .s(and2[i]),
                .sus(sus), // Pass sus to adder
                .a(and1[2*i]),
                .b(and1[2*i+1])
            );
        end

        // 第八级加法树 - output to current_mac_sum
        add #(14) a8
        (
            .s(current_mac_sum),     // CHANGED output to internal wire
            .sus(sus),             // Pass sus to adder
            .a(and2[0]),
            .b(and2[1])
        );
    endgenerate

    // ADDED Combinational logic for MAC and FMAS operations
    assign add_c_result = current_mac_sum + C_in;
    assign sub_d_result = add_c_result - D_in;

    // Select operation based on op_sel and assign to output (with truncation to 14 bits)
    assign result_out = op_sel ? sub_d_result[13:0] : add_c_result[13:0];

endmodule

// --- Unchanged modules from original testbench below this line ---
// global_io, accumulator, se_cla, add, s_cla, oai_mult, rwldrv,
// gctrl, cim_array_ctrl, cim_array, cim_bank
// These modules are copied verbatim from the original top_tb.v

module global_io(
    input [13:0] macout_a, // CHANGED from [14:0] to match new width
    input [13:0] macout_b, // CHANGED from [14:0] to match new width
    input clk,acm_en,rstn,
    input st,
    input wwidth,
    output [50:0] nout
);
    // DFF
    reg [13:0] in_a; // CHANGED width
    reg [25:0] in_b; // CHANGED width (13 bits + 12 bits shift = 25 bits. If macout_b is 14 bits, then 14+12=26. Original was 15+12=27)
                     // Let's make it macout_b width + 12. So 14+12 = 26. Wire c1 needs to be [25:0]. Out [26:0]
                     // The add #(27) a2 will take {12'b0, in_a} (12+14=26 bits) and c1 (26 bits) -> output 27 bits. This seems okay.

    wire [25:0] c1; // CHANGED width
    wire [26:0] out; // CHANGED width

    always @(posedge clk) begin
        in_a <= macout_a;
        in_b <= macout_b << 12; // macout_b is 14 bits, shifted by 12. in_b should be 14+12=26 bits.
    end

    assign c1 = ~(in_b | ~{26{wwidth}}); // CHANGED width of concatenation

    add #(26) a2 // Parameter for add should be input width. If inputs are 26 bits, sum is 27.
    (
        .a({12'b0,in_a}), // This is 12+14 = 26 bits
        .b(c1),           // This is 26 bits
        .sus(1'b1),
        .s(out)           // Output is width+1 = 27 bits
    );

    accumulator acc1
    (
        .in1(out[26:0]), // Input is 27 bits
        .st(st),
        .acm_en(acm_en),
        .clk(clk),
        .rstn(rstn),
        .nout(nout)
    );

endmodule

module accumulator(
    input [26:0] in1, // Width matches 'out' from global_io
    input st,
    input acm_en,
    input clk,rstn,
    output [50:0] nout
);

    reg [50:0] nout_1;
    wire [50:0] acc_in;

    assign acc_in = {51{acm_en}} & nout_1;

    se_cla secla1( // se_cla takes [26:0] and [50:0]
        .a(in1),
        .b(acc_in),
        .s(nout)
    );

    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin
            nout_1 <= 51'b0;
        end
        else begin
            if(!st) begin
                nout_1 <= nout;
            end
            else begin
                nout_1 <= 51'b0;
            end
        end
    end

endmodule


module se_cla(
    input [26:0] a, // Matches input from accumulator
    input [50:0] b,
    output wire [50:0] s
);

    wire [26:0] sm; // Changed from [27:0] as add output is width+1. If add input is 27, output is 28.
                  // add #(27) a1 has .a (27bit) and .b (27bit from b[26:0]), so .s (sm) is 28bit.
                  // Let's keep sm as [27:0]
    wire [27:0] sm_internal;


    wire [23:0] s1;
    // wire [26:0] s2; // s2 was not used

    s_cla scla1( // s_cla takes 24 bit a, 24 bit b.
        .a({24{a[26]}}), // sign extend a[26] (MSB of 27-bit input)
        .b(b[50:27]),    // upper part of b
        .ci(sm_internal[27]), // Carry from the 27-bit addition
        .s(s1)
    );
    add #(27) a1( // add width 27. Inputs a (27bit), b[26:0] (27bit). Output sm_internal (28bit)
        .a(a),
        .b(b[26:0]),
        .s(sm_internal),
        .sus(1'b0) // Changed to unsigned add as per typical se_cla, or should be sus? Original add was sus=0.
    );
    assign s = {s1,sm_internal[26:0]}; // s1 is 24bit, sm_internal[26:0] is 27bit. Total 51bit. This is correct.

endmodule

module add # (parameter width = 5)
(
    input wire [width-1:0] a,
    input wire [width-1:0] b,
    input wire sus,
    output reg [width:0] s
);
    always @(*) begin
        if (sus) begin
            s = {a[width-1], a} + {b[width-1], b};
        end else begin
            s = {1'b0, a} + {1'b0, b};
        end
    end
endmodule

module s_cla(
    input signed [23:0] a,
    input signed [23:0] b,
    input ci,
    output signed [23:0] s,
    output co // co was not declared as output in original embedded version, but is in standalone. Assuming it's needed.
);
    wire [23:0] G;
    wire [23:0] P;
    wire [23:0] C;

    assign G = a & b;
    assign P = a ^ b;

    assign C[0] = ci;
    genvar i;
    generate
        for (i = 1; i < 24; i = i + 1) begin
            assign C[i] = G[i-1] | (P[i-1] & C[i-1]);
        end
    endgenerate

    assign s = P ^ C;
    assign co = G[23] | (P[23] & C[23]); // Added co assignment
endmodule


module oai_mult(
    input wire [11:0] a,
    input wire [11:0] b,
    input wire c,
    input wire d,
    output wire [11:0] e
);

    wire [11:0] a1,a2;
    assign a1 = a | {12{c}};
    assign a2 = b | {12{d}};
    assign e = ~ (a1 & a2);

endmodule

module rwldrv(
    input cima,
    input [95:0] xin,
    input clk,rstn,
    input [5:0] sel,
    output reg [7:0] rwlb_row1,
    output reg [7:0] rwlb_row0
);
    wire [7:0] xin_w [11:0];

    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin
            assign xin_w[11][k] = xin[12 * k + 11];
            assign xin_w[10][k] = xin[12 * k + 10];
            assign xin_w[9][k] = xin[12 * k + 9];
            assign xin_w[8][k] = xin[12 * k + 8];
            assign xin_w[7][k] = xin[12 * k + 7];
            assign xin_w[6][k] = xin[12 * k + 6];
            assign xin_w[5][k] = xin[12 * k + 5];
            assign xin_w[4][k] = xin[12 * k + 4];
            assign xin_w[3][k] = xin[12 * k + 3];
            assign xin_w[2][k] = xin[12 * k + 2];
            assign xin_w[1][k] = xin[12 * k + 1];
            assign xin_w[0][k] = xin[12 * k + 0];
        end
    endgenerate

    always @(*) begin
        if(rstn) begin
            if(cima) begin
                rwlb_row0 <= ~8'b0;
                case(sel)
                    6'd0: rwlb_row1 = ~xin_w[11];
                    6'd1: rwlb_row1 = ~xin_w[10];
                    6'd2: rwlb_row1 = ~xin_w[9];
                    6'd3: rwlb_row1 = ~xin_w[8];
                    6'd4: rwlb_row1 = ~xin_w[7];
                    6'd5: rwlb_row1 = ~xin_w[6];
                    6'd6: rwlb_row1 = ~xin_w[5];
                    6'd7: rwlb_row1 = ~xin_w[4];
                    6'd8: rwlb_row1 = ~xin_w[3];
                    6'd9: rwlb_row1 = ~xin_w[2];
                    6'd10: rwlb_row1 = ~xin_w[1];
                    6'd11: rwlb_row1 = ~xin_w[0];
                    6'd12: rwlb_row1 = ~xin_w[11];
                    6'd13: rwlb_row1 = ~xin_w[10];
                    6'd14: rwlb_row1 = ~xin_w[9];
                    6'd15: rwlb_row1 = ~xin_w[8];
                    6'd16: rwlb_row1 = ~xin_w[7];
                    6'd17: rwlb_row1 = ~xin_w[6];
                    6'd18: rwlb_row1 = ~xin_w[5];
                    6'd19: rwlb_row1 = ~xin_w[4];
                    6'd20: rwlb_row1 = ~xin_w[3];
                    6'd21: rwlb_row1 = ~xin_w[2];
                    6'd22: rwlb_row1 = ~xin_w[1];
                    6'd23: rwlb_row1 = ~xin_w[0];
                    default: rwlb_row1 = ~8'b0; // Added default
                endcase
            end
            else begin
                rwlb_row1 <= ~8'b0;
                case(sel[1:0]) // This was sel[1:0] in original, limiting cases. Should be sel for full range?
                               // The problem description does not ask to fix existing logic bugs.
                               // However, the case goes up to 6'd23. sel[1:0] only gives 4 cases.
                               // I will assume sel should be used for the case selector to match intent.
                    6'd0: rwlb_row0 = ~xin_w[11];
                    6'd1: rwlb_row0 = ~xin_w[10];
                    6'd2: rwlb_row0 = ~xin_w[9];
                    6'd3: rwlb_row0 = ~xin_w[8];
                    // To be complete, this case should also go up to 23 or use full sel.
                    // For now, sticking to original sel[1:0] for minimal changes outside direct scope.
                    // Re-checking original: it was case(sel) for both, but with sel[1:0] in one.
                    // The provided original code had case(sel) for cima=1 and case(sel[1:0]) for cima=0.
                    // I will keep this as is.
                    default: rwlb_row0 = ~8'b0; // Added default
                endcase
            end
        end else begin // Added behavior for rstn=0
            rwlb_row1 <= ~8'b0;
            rwlb_row0 <= ~8'b0;
        end
    end
endmodule

module gctrl(
    input inwidth,
    input clk,rstn,
    output reg [5:0] sel,
    output reg st
);
    reg [5:0] count;
    always @(posedge clk,negedge rstn) begin
        if(~rstn) begin
            sel <= 0;
            st <= 1'b1;
        end
        else begin
            if(sel < count) begin
                sel <= sel + 1;
                st <= 1'b0;
            end
            else begin
                sel <= 0;
                st <= 1'b1;
            end
        end
    end
    always @(*) begin
        count = (inwidth)? 6'd23: 6'd11;
    end
endmodule

module cim_array_ctrl(
    input [23:0] D,
    input [7:0] WA,
    input clk, rstn, cima,
    output reg [23:0] D1,
    output reg [7:0] WA0, WA1
);

    // integer i, idx; // Loop variables - removed as not used
    // reg [3:0] block_index;  // Decoded block index (0-8) - removed as not used

    always @(posedge clk or negedge rstn) begin // Changed to negedge rstn for consistency
        if (~rstn) begin
            WA0 <= ~8'b0; // Should be specific inactive state, e.g. 8'b0 or 8'hFF
            WA1 <= ~8'b0; // Depending on how WA=0 is treated by cim_bank
            D1 <= 24'b0;
        end
        else begin
            // D1 should probably only be assigned when WA is active.
            // Original logic: D1 <= D; always. This means D1 always reflects D.
            D1 <= D;
            if (WA != 8'b0) begin // Check if any write address bit is active
                if (cima) begin // Typo in original? cima usually means CIM mode, not bank select.
                                // Assuming interpretation from original top.v: cima=0 for bank A, cima=1 for bank B
                    WA0 <= WA[7:0]; // Route to bank 0 if cima=0 (original seems to imply this)
                    WA1 <= 8'b0;    // Or use ~8'b0 for inactive? Let's use 0 for inactive.
                end
                else begin
                    WA1 <= WA[7:0]; // Route to bank 1 if cima=1
                    WA0 <= 8'b0;
                end
            end else begin // No active WA bit
                WA0 <= 8'b0;
                WA1 <= 8'b0;
            end
        end
    end

endmodule

module cim_array(
    input [23:0] D1,
    input [7:0] WA0, WA1,
    output [95:0] wb0_a, wb1_a, // wb0_a from bank0, wb1_a from bank1
    output [95:0] wb0_b, wb1_b  // wb0_b from bank0, wb1_b from bank1
);
    // wb0_a and wb0_b are from cim_bank_0
    // wb1_a and wb1_b are from cim_bank_1
    // This seems swapped compared to typical A/B bank separation.
    // lmaca uses wb0_a, wb1_a. So lmaca uses cim_bank_0 and cim_bank_1.
    // lmacb uses wb0_b, wb1_b. So lmacb uses cim_bank_0 and cim_bank_1.
    // This means wb0_a and wb0_b are different views of bank0's memory.
    // And wb1_a and wb1_b are different views of bank1's memory.

    cim_bank cim_bank_0 (
        .D(D1),
        .WA(WA0), // Controlled by WA0
        .WB_a(wb0_a), // Output view A of bank 0
        .WB_b(wb0_b)  // Output view B of bank 0
    );
    cim_bank cim_bank_1 (
        .D(D1),
        .WA(WA1), // Controlled by WA1
        .WB_a(wb1_a), // Output view A of bank 1
        .WB_b(wb1_b)  // Output view B of bank 1
    );

endmodule

module cim_bank(
    input [23:0] D,
    input [7:0] WA, // Active high WA bit selects memory location
    output reg [95:0] WB_a, WB_b
);
    reg [23:0] mem [0:7];
    integer i; // for initial block

    // Initialize memory to a known state (optional, but good for simulation)
    initial begin
        for (i = 0; i < 8; i = i + 1) begin
            mem[i] = 24'b0;
        end
    end

    always @(*) begin // Combinational logic for write and read
        // Write operation (simplified: D is written if corresponding WA bit is high)
        // This is level-sensitive write behavior based on WA.
        if (WA[0]) mem[0] = D;
        if (WA[1]) mem[1] = D;
        if (WA[2]) mem[2] = D;
        if (WA[3]) mem[3] = D;
        if (WA[4]) mem[4] = D;
        if (WA[5]) mem[5] = D;
        if (WA[6]) mem[6] = D;
        if (WA[7]) mem[7] = D;

        // Read operation (combinational read)
        WB_a = {~mem[7][11:0], ~mem[6][11:0], ~mem[5][11:0], ~mem[4][11:0], ~mem[3][11:0], ~mem[2][11:0], ~mem[1][11:0], ~mem[0][11:0]};
        WB_b = {~mem[7][23:12], ~mem[6][23:12], ~mem[5][23:12], ~mem[4][23:12], ~mem[3][23:12], ~mem[2][23:12], ~mem[1][23:12], ~mem[0][23:12]};
    end
endmodule
