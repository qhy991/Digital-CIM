`timescale 1ns / 1ps

module top_tb();
    reg [23:0] D;
    reg clk,rstn,cima,acm_en;
    reg [7:0] WA;
    reg inwidth;
    reg wwidth;
    reg [95:0] xin0;
    // New TB registers for C_in, D_in, op_sel
    reg [11:0] C_in_tb;
    reg [11:0] D_in_tb;
    reg op_sel_tb;

    wire [50:0] nout;
    wire st;
    // New wires for mac results from top
    wire [13:0] mac_res_a_tb;
    wire [13:0] mac_res_b_tb;

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
        // Connect new top inputs
        .C_in(C_in_tb),
        .D_in(D_in_tb),
        .op_sel(op_sel_tb),
        .nout(nout),
        .st(st),
        // Connect new top outputs for mac results
        .mac_res_a(mac_res_a_tb),
        .mac_res_b(mac_res_b_tb)
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
        xin0 = 0;
        // Initialize new inputs
        C_in_tb = 0;
        D_in_tb = 0;
        op_sel_tb = 0;

        #10 rstn = 1;
        D = ~24'b0;
        #5 WA = 8'b00000001;
        #5 WA = 8'b00000010;
        #5 WA = 8'b00000100;
        // Example to make xin0 more deterministic for oai_mult behavior
        xin0 = 96'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA; // Pattern for xin0

        #50;

        #20;

        $display("SIM_INFO: Starting New Tests");

        $display("TEST_CASE: FMAS Operation (op_sel=1)");
        op_sel_tb = 1'b1;
        C_in_tb = 12'd10;
        D_in_tb = 12'd5;
        #10;
        $display("FMAS_RESULT: op_sel=%b, C_in=%d, D_in=%d => mac_res_a_tb=%d (0x%h), mac_res_b_tb=%d (0x%h)",
                 op_sel_tb, C_in_tb, D_in_tb, mac_res_a_tb, mac_res_a_tb, mac_res_b_tb, mac_res_b_tb);

        $display("TEST_CASE: MAC Operation (op_sel=0, A*B+C)");
        op_sel_tb = 1'b0;
        C_in_tb = 12'd20;
        D_in_tb = 12'd7;
        #10;
        $display("MAC_RESULT (A*B+C): op_sel=%b, C_in=%d, D_in=%d => mac_res_a_tb=%d (0x%h), mac_res_b_tb=%d (0x%h)",
                 op_sel_tb, C_in_tb, D_in_tb, mac_res_a_tb, mac_res_a_tb, mac_res_b_tb, mac_res_b_tb);

        $display("TEST_CASE: Original MAC-like behavior (op_sel=0, C_in=0)");
        op_sel_tb = 1'b0;
        C_in_tb = 12'd0;
        D_in_tb = 12'd0;
        #10;
        $display("ORIG_MAC_RESULT (A*B): op_sel=%b, C_in=%d, D_in=%d => mac_res_a_tb=%d (0x%h), mac_res_b_tb=%d (0x%h)",
                 op_sel_tb, C_in_tb, D_in_tb, mac_res_a_tb, mac_res_a_tb, mac_res_b_tb, mac_res_b_tb);

        #20;
        $finish;
    end
    initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0);
    end

endmodule

module top(
    input [23:0] D,
    input clk,rstn,cima,acm_en,
    input [7:0] WA,
    input inwidth,
    input wwidth,
    input [95:0] xin0,
    input wire [11:0] C_in,
    input wire [11:0] D_in,
    input wire op_sel,
    output [50:0] nout,
    output wire st,
    output wire [13:0] mac_res_a,
    output wire [13:0] mac_res_b
);
    wire [13:0] macout_a,macout_b;
    wire [95:0] wb0_a,wb1_a,wb0_b,wb1_b;
    wire [7:0] rwlb_row1,rwlb_row0;
    wire [5:0] sel;
    wire [23:0] D1;
    wire [7:0] WA0, WA1;

    global_io global_io_u(
        .macout_a({1'b0, macout_a}),
        .macout_b({1'b0, macout_b}),
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
        .C_in(C_in),
        .D_in(D_in),
        .op_sel(op_sel),
        .sus(1'b0),
        .result_out(macout_a)
    );

    local_mac lmacb(
        .wb0(wb0_b),
        .wb1(wb1_b),
        .rwlb_row1(rwlb_row1),
        .rwlb_row0(rwlb_row0),
        .C_in(C_in),
        .D_in(D_in),
        .op_sel(op_sel),
        .sus(~wwidth),
        .result_out(macout_b)
    );

    assign mac_res_a = macout_a;
    assign mac_res_b = macout_b;

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

module global_io(
    input [14:0] macout_a,
    input [14:0] macout_b,
    input clk,acm_en,rstn,
    input st,
    input wwidth,
    output [50:0] nout
);
    reg [14:0] in_a;
    reg [26:0] in_b;
    wire [26:0] c1;
    wire [27:0] out;
    always @(posedge clk) begin
        in_a <= macout_a;
        in_b <= macout_b << 12;
    end
    assign c1 = ~(in_b | ~{27{wwidth}});
    add #(27) a2
    (
        .a({12'b0,in_a}),
        .b(c1),
        .sus(1'b1),
        .s(out)
    );
    accumulator acc1
    (
        .in1(out[26:0]),
        .st(st),
        .acm_en(acm_en),
        .clk(clk),
        .rstn(rstn),
        .nout(nout)
    );
endmodule

module accumulator(
    input [26:0] in1,
    input st,
    input acm_en,
    input clk,rstn,
    output [50:0] nout
);
    reg [50:0] nout_1;
    wire [50:0] acc_in;
    assign acc_in = {51{acm_en}} & nout_1;
    se_cla secla1(
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
    input [26:0] a,
    input [50:0] b,
    output wire [50:0] s
);
    wire [27:0] sm;
    wire [23:0] s1;
    assign s = {s1,sm[26:0]}; // s2 was unused
    s_cla scla1(
        .a({24{a[26]}}),
        .b(b[50:27]),
        .ci(sm[27]), // check bit index
        .s(s1)
    );
    add #(27) a1(
        .a(a),
        .b(b[26:0]),
        .s(sm),
        .sus(1'b0)
    );
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
    output co // co was not declared as output in original
);
    wire [23:0] G;
    wire [23:0] P;
    wire [23:0] C;
    assign G = a & b;
    assign P = a ^ b;
    assign C[0] = ci;
    genvar i_scla;
    generate
        for (i_scla = 1; i_scla < 24; i_scla = i_scla + 1) begin // Corrected genvar name
            assign C[i_scla] = G[i_scla-1] | (P[i_scla-1] & C[i_scla-1]);
        end
    endgenerate
    assign s = P ^ C;
    assign co = G[23] | (P[23] & C[23]);
endmodule

module local_mac(
    input [95:0] wb0,
    input [95:0] wb1,
    input [7:0] rwlb_row1,
    input [7:0] rwlb_row0,
    input sus,
    input [11:0] C_in,
    input [11:0] D_in,
    input op_sel,
    output reg [13:0] result_out
);
    wire [11:0] wb0_sig [0:7];
    wire [11:0] wb1_sig [0:7];
    wire [11:0] XINxW [0:7];
    wire [12:0] and1 [0:3];
    wire [13:0] and2 [0:1];
    wire [14:0] final_adder_sum_signal;

    genvar idx_lm;
    generate
        for (idx_lm = 0; idx_lm < 8; idx_lm = idx_lm + 1) begin
            assign wb0_sig[idx_lm] = wb0[idx_lm*12 +: 12];
            assign wb1_sig[idx_lm] = wb1[idx_lm*12 +: 12];
        end
    endgenerate

    genvar i_lm,j_lm;
    generate
        for (j_lm = 0; j_lm < 8; j_lm = j_lm + 1) begin:mult_array
            oai_mult m1 (
                .a(wb0_sig[j_lm]),
                .b(wb1_sig[j_lm]),
                .c(rwlb_row0[j_lm]),
                .d(rwlb_row1[j_lm]),
                .e(XINxW[j_lm])
            );
        end

        for (i_lm = 0; i_lm < 4; i_lm = i_lm + 1) begin
            add #(12) a1 (.s(and1[i_lm]), .sus(sus), .a(XINxW[2*i_lm]), .b(XINxW[2*i_lm+1]));
        end

        for (i_lm = 0; i_lm < 2; i_lm = i_lm + 1) begin
            add #(13) a2 (.s(and2[i_lm]), .sus(sus), .a(and1[2*i_lm]), .b(and1[2*i_lm+1]));
        end

        add #(14) a8 (.s(final_adder_sum_signal), .sus(sus), .a(and2[0]), .b(and2[1]));
    endgenerate

    wire [15:0] sum_with_C_val;
    wire [15:0] fmas_val;

    assign sum_with_C_val = final_adder_sum_signal + C_in;
    assign fmas_val = sum_with_C_val - D_in;

    always @(*) begin
        if (op_sel) begin
            result_out = fmas_val[13:0];
        end else begin
            result_out = sum_with_C_val[13:0];
        end
    end
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
    genvar k_rw;
    generate
        for (k_rw = 0; k_rw < 8; k_rw = k_rw + 1) begin
            assign xin_w[11][k_rw] = xin[12 * k_rw + 11];
            assign xin_w[10][k_rw] = xin[12 * k_rw + 10];
            assign xin_w[9][k_rw] = xin[12 * k_rw + 9];
            assign xin_w[8][k_rw] = xin[12 * k_rw + 8];
            assign xin_w[7][k_rw] = xin[12 * k_rw + 7];
            assign xin_w[6][k_rw] = xin[12 * k_rw + 6];
            assign xin_w[5][k_rw] = xin[12 * k_rw + 5];
            assign xin_w[4][k_rw] = xin[12 * k_rw + 4];
            assign xin_w[3][k_rw] = xin[12 * k_rw + 3];
            assign xin_w[2][k_rw] = xin[12 * k_rw + 2];
            assign xin_w[1][k_rw] = xin[12 * k_rw + 1];
            assign xin_w[0][k_rw] = xin[12 * k_rw + 0];
        end
    endgenerate
    always @(*) begin
        if(rstn) begin
            if(cima) begin
                rwlb_row0 <= ~8'b0;
                case(sel)
                    6'd0: rwlb_row1 = ~xin_w[11]; 6'd1: rwlb_row1 = ~xin_w[10]; 6'd2: rwlb_row1 = ~xin_w[9];
                    6'd3: rwlb_row1 = ~xin_w[8];  6'd4: rwlb_row1 = ~xin_w[7];  6'd5: rwlb_row1 = ~xin_w[6];
                    6'd6: rwlb_row1 = ~xin_w[5];  6'd7: rwlb_row1 = ~xin_w[4];  6'd8: rwlb_row1 = ~xin_w[3];
                    6'd9: rwlb_row1 = ~xin_w[2];  6'd10: rwlb_row1 = ~xin_w[1]; 6'd11: rwlb_row1 = ~xin_w[0];
                    6'd12: rwlb_row1 = ~xin_w[11];6'd13: rwlb_row1 = ~xin_w[10];6'd14: rwlb_row1 = ~xin_w[9];
                    6'd15: rwlb_row1 = ~xin_w[8]; 6'd16: rwlb_row1 = ~xin_w[7]; 6'd17: rwlb_row1 = ~xin_w[6];
                    6'd18: rwlb_row1 = ~xin_w[5]; 6'd19: rwlb_row1 = ~xin_w[4]; 6'd20: rwlb_row1 = ~xin_w[3];
                    6'd21: rwlb_row1 = ~xin_w[2]; 6'd22: rwlb_row1 = ~xin_w[1]; 6'd23: rwlb_row1 = ~xin_w[0];
                    default: rwlb_row1 = ~xin_w[11];
                endcase
            end
            else begin
                rwlb_row1 <= ~8'b0;
                case(sel) // Corrected from sel[1:0]
                    6'd0: rwlb_row0 = ~xin_w[11]; 6'd1: rwlb_row0 = ~xin_w[10]; 6'd2: rwlb_row0 = ~xin_w[9];
                    6'd3: rwlb_row0 = ~xin_w[8];  6'd4: rwlb_row0 = ~xin_w[7];  6'd5: rwlb_row0 = ~xin_w[6];
                    6'd6: rwlb_row0 = ~xin_w[5];  6'd7: rwlb_row0 = ~xin_w[4];  6'd8: rwlb_row0 = ~xin_w[3];
                    6'd9: rwlb_row0 = ~xin_w[2];  6'd10: rwlb_row0 = ~xin_w[1]; 6'd11: rwlb_row0 = ~xin_w[0];
                    6'd12: rwlb_row0 = ~xin_w[11];6'd13: rwlb_row0 = ~xin_w[10];6'd14: rwlb_row0 = ~xin_w[9];
                    6'd15: rwlb_row0 = ~xin_w[8]; 6'd16: rwlb_row0 = ~xin_w[7]; 6'd17: rwlb_row0 = ~xin_w[6];
                    6'd18: rwlb_row0 = ~xin_w[5]; 6'd19: rwlb_row0 = ~xin_w[4]; 6'd20: rwlb_row0 = ~xin_w[3];
                    6'd21: rwlb_row0 = ~xin_w[2]; 6'd22: rwlb_row0 = ~xin_w[1]; 6'd23: rwlb_row0 = ~xin_w[0];
                    default: rwlb_row0 = ~xin_w[11];
                endcase
            end
        end else begin
             rwlb_row1 <= 8'hFF;
             rwlb_row0 <= 8'hFF;
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
    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            WA0 <= 8'b0; // Initialize to 0 for clarity
            WA1 <= 8'b0; // Initialize to 0 for clarity
            D1 <= 24'b0;
        end
        else begin
            if (WA != 8'b0) begin
                D1 <= D;
                if (cima) begin
                    WA0 <= WA;
                    WA1 <= 8'b0;
                end
                else begin
                    WA1 <= WA;
                    WA0 <= 8'b0;
                end
            end else begin
                 WA0 <= 8'b0;
                 WA1 <= 8'b0;
                 // D1 retains value or cleared - original was unclear, retaining is fine.
            end
        end
    end
endmodule

module cim_array(
    input [23:0] D1,
    input [7:0] WA0, WA1,
    output [95:0] wb0_a, wb1_a,
    output [95:0] wb0_b, wb1_b
);
    cim_bank cim_bank_0 (
        .D(D1),
        .WA(WA0),
        .WB_a(wb0_a),
        .WB_b(wb0_b)
    );
    cim_bank cim_bank_1 (
        .D(D1),
        .WA(WA1),
        .WB_a(wb1_a),
        .WB_b(wb1_b)
    );
endmodule

module cim_bank(
    input [23:0] D,
    input [7:0] WA,
    output reg [95:0] WB_a,
    output reg [95:0] WB_b
);
    reg [23:0] mem [0:7];
    integer k_cb;

    // Initialize memory to 0 to prevent X values if read before write.
    integer init_idx;
    initial begin
        for (init_idx = 0; init_idx < 8; init_idx = init_idx + 1) begin
            mem[init_idx] = 24'b0;
        end
    end

    always @(*) begin
        // Write operation based on WA
        // This combinational write is problematic in real hardware but matches original structure.
        for (k_cb = 0; k_cb < 8; k_cb = k_cb + 1) begin
            if (WA == (1 << k_cb)) begin
                mem[k_cb] = D;
            end
        end

        // Read operation (always active)
        WB_a = {~mem[7][11:0], ~mem[6][11:0], ~mem[5][11:0], ~mem[4][11:0], ~mem[3][11:0], ~mem[2][11:0], ~mem[1][11:0], ~mem[0][11:0]};
        WB_b = {~mem[7][23:12], ~mem[6][23:12], ~mem[5][23:12], ~mem[4][23:12], ~mem[3][23:12], ~mem[2][23:12], ~mem[1][23:12], ~mem[0][23:12]};
    end
endmodule
