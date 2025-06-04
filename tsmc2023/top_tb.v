`timescale 1ns / 1ps

module top_tb();
    reg [191:0] D;
    reg clk,rstn,cima,acm_en;
    reg [8:0] WA;
    reg [1:0] inwidth;
    reg wwidth;
    reg [575:0] xin0;
    wire [35:0] nout;

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
        .nout(nout)
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
        inwidth = 00;
        wwidth = 0;
        xin0 = 0;
        #10 rstn = 1;
        D = ~192'b0;
        #5 WA = 1;
        #5 WA = 2;
        #5 WA = 4;
        #5 WA = 8;
        #5 WA = 16;
        #5 WA = 32;
        #5 WA = 64;
        #5 WA = 128;
        #5 WA = 256;
        #10 cima = 1;xin0=~576'b0/13;
        #500 $finish;
    end
    initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0);
    end

endmodule

module top(
    input [191:0] D,
    input clk,rstn,cima,acm_en,
    input [8:0] WA,
    input [1:0] inwidth,
    input wwidth,
    input [575:0] xin0,
    output [35:0] nout,
    output wire st
);  
    wire [11:0] macout_a,macout_b,macout_c;
    wire [575:0] wb0_a,wb1_a,wb0_b,wb1_b,wb0_c,wb1_c;
    wire [143:0] rwlb_row1,rwlb_row0;
    wire [3:0] sel;
    
    global_io global_io_u(
        .macout_a(macout_a),
        .macout_b(macout_b),
        .macout_c(macout_c),
        .clk(clk),
        .acm_en(acm_en),
        .rstn(rstn),
        .st(st),
        .wwidth(wwidth),
        .nout(nout)
    );

    cim_array cim_array_u(
        .D(D),
        .WA(WA),
        .clk(clk),
        .rstn(rstn),
        .cima(cima),
        .wb0_a(wb0_a),
        .wb1_a(wb1_a),
        .wb0_b(wb0_b),
        .wb1_b(wb1_b),
        .wb0_c(wb0_c),
        .wb1_c(wb1_c)
    );

    local_mac lmaca(
        .wb0(wb0_a),
        .wb1(wb1_a),
        .rwlb_row1(rwlb_row1),
        .rwlb_row0(rwlb_row0),
        .sus(1'b0),
        .mac_out(macout_a)
    );

    local_mac lmacb(
        .wb0(wb0_b),
        .wb1(wb1_b),
        .rwlb_row1(rwlb_row1),
        .rwlb_row0(rwlb_row0),
        .sus(~wwidth),
        .mac_out(macout_b)
    );

    local_mac lmacc(
        .wb0(wb0_c),
        .wb1(wb1_c),
        .rwlb_row1(rwlb_row1),
        .rwlb_row0(rwlb_row0),
        .sus(wwidth),
        .mac_out(macout_c)
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

module global_io(
    input [11:0] macout_a,
    input [11:0] macout_b,
    input [11:0] macout_c,
    input clk,acm_en,rstn,
    input st,
    input wwidth,
    output [35:0] nout
);
    // DFF
    reg [11:0] in_a;
    reg [15:0] in_b;
    reg [19:0] in_c;

    wire [19:0] c1;
    wire [16:0] out1;
    wire [20:0] out2;

    always @(posedge clk) begin
        in_a <= macout_a;
        in_b <= macout_b << 4;
        in_c <= macout_c << 8;
    end

    add #(16) a1
    (
        .a({4'b0,in_a}),
        .b(in_b),
        .sus(~wwidth),
        .s(out1)
    );

    assign c1 = ~(in_c | ~wwidth);

    add #(20) a2
    (
        .a({4'b0,out1[15:0]}),
        .b(in_c),
        .sus(wwidth),
        .s(out2)
    );

    accumulator acc1
    (
        .in1(out2[19:0]),
        .st(st),
        .acm_en(acm_en),
        .clk(clk),
        .rstn(rstn),
        .nout(nout)
    );
    
endmodule

module accumulator(
    input [19:0] in1,
    input st,
    input acm_en,
    input clk,rstn,
    output [35:0] nout
);

    reg [35:0] nout_1;
    wire [35:0] acc_in;
    
    assign acc_in = {36{acm_en}} & nout_1;

    se_cla secla1(
        .a(in1),
        .b(acc_in),
        .s(nout)
    );

    always @(posedge clk,negedge rstn) begin
        if(!rstn) begin
            nout_1 <= 0;
        end
        else begin
            if(!st) begin
                nout_1 <= nout;
            end
            else begin
                nout_1 <= 0;
            end
        end
    end

endmodule

module se_cla(
    input [19:0] a,
    input [35:0] b,
    output wire [35:0] s
);

    wire [20:0] sm;
    wire [15:0] s1;
    wire [19:0] s2;
    
    s_cla scla1(
        .a({16{a[19]}}),
        .b(b[35:20]),
        .ci(sm[20]),
        .s(s1)
    );
    add #(20) a1(
        .a(a),
        .b(b[19:0]),
        .s(sm),
        .sus(1'b0)
    );
    assign s = {s1,sm[19:0]};

endmodule

module add # (parameter width = 5)
(
    input wire [width-1:0] a,
    input wire [width-1:0] b,
    input wire sus,  // sus = 1: 有符号加法, sus = 0: 无符号加法
    output reg [width:0] s  // 结果扩展 1 位
);
    always @(*) begin
        if (sus) begin
            // 有符号加法：符号扩展后加法
            s = {a[width-1], a} + {b[width-1], b};
        end else begin
            // 无符号加法：高位补 0
            s = {1'b0, a} + {1'b0, b};
        end
    end
endmodule

module s_cla(
    input signed [15:0] a,
    input signed [15:0] b,
    input ci,
    output signed [15:0] s,
    output co
);
    wire [15:0] G;  // 生成信号
    wire [15:0] P;  // 传播信号
    wire [15:0] C;  // 进位信号

    // 生成和传播信号
    assign G = a & b;
    assign P = a ^ b;

    // 计算进位
    assign C[0] = ci;
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin
            assign C[i] = G[i-1] | (P[i-1] & C[i-1]);
        end
    endgenerate

    // 计算和
    assign s = P ^ C;

    // 计算无符号进位输出
    assign co = G[15] | (P[15] & C[15]);

endmodule

module cim_array(
    input [191:0] D,         // 192-bit data input, containing 16 blocks of 12-bit data each
    input [8:0] WA,          // 9-bit one-hot write address
    input clk, rstn, cima, 
    output reg [575:0] wb0_a, wb1_a,
    output reg [575:0] wb0_b, wb1_b,
    output reg [575:0] wb0_c, wb1_c
);
    // Memory arrays, each with a depth of 144 and 12-bit width per cell
    reg [11:0] mem_0 [0:143];  
    reg [11:0] mem_1 [0:143];
    
    integer i, idx;  // Loop variables
    reg [3:0] block_index;  // Decoded block index (0-8)

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            // Reset all memory cells
            for (i = 0; i <= 143; i = i + 1) begin
                mem_0[i] <= 12'b0;
                mem_1[i] <= 12'b0;
            end
        end 
        else begin
            // Split memory content and map to output wbX_Y
            for (i = 0; i <= 143; i = i + 1) begin
                wb1_a[i*4 +: 4] <= ~mem_1[i][3:0];
                wb1_b[i*4 +: 4] <= ~mem_1[i][7:4];
                wb1_c[i*4 +: 4] <= ~mem_1[i][11:8];
                wb0_a[i*4 +: 4] <= ~mem_0[i][3:0];
                wb0_b[i*4 +: 4] <= ~mem_0[i][7:4];
                wb0_c[i*4 +: 4] <= ~mem_0[i][11:8];
            end

            // Decode WA from one-hot encoding to a binary block index
            case(WA)
                9'b000000001: block_index = 0;
                9'b000000010: block_index = 1;
                9'b000000100: block_index = 2;
                9'b000001000: block_index = 3;
                9'b000010000: block_index = 4;
                9'b000100000: block_index = 5;
                9'b001000000: block_index = 6;
                9'b010000000: block_index = 7;
                9'b100000000: block_index = 8;
                default:      block_index = 0;
            endcase

            // valid write
            if (WA != 9'b0) begin
                if (cima) begin
                    for (idx = 0; idx < 16; idx = idx + 1) begin
                        mem_0[block_index * 16 + idx] <= D[idx*12 +: 12];
                    end
                end 
                else begin
                    for (idx = 0; idx < 16; idx = idx + 1) begin
                        mem_1[block_index * 16 + idx] <= D[idx*12 +: 12];
                    end
                end
            end
        end
    end
endmodule

module local_mac(
    input [575:0] wb0,
    input [575:0] wb1,
    input [143:0] rwlb_row1,
    input [143:0] rwlb_row0,
    input sus,
    output wire [11:0] mac_out
);
    wire [3:0] wb0_sig [0:143];
    wire [3:0] wb1_sig [0:143];
    wire [3:0] XINxW [0:143];
    wire [4:0] and1 [0:71];
    wire [5:0] and2 [0:35];
    wire [6:0] and3 [0:17];
    wire [7:0] and4 [0:8];
    wire [8:0] and5 [0:4];
    wire [9:0] and6 [0:2];
    wire [10:0] and7 [0:1];

    assign and5[4] = and4[8];
    assign and6[2] = and5[4];
    assign and7[1] = and6[2];

    genvar idx;
    generate
        for (idx = 0; idx < 144; idx = idx + 1) begin
            assign wb0_sig[idx] = wb0[idx*4 +: 4];
            assign wb1_sig[idx] = wb1[idx*4 +: 4];
        end
    endgenerate
    
    genvar i,j;
    generate
        // 例化OAI乘法器
        for (j = 0; j < 144; j = j + 1) begin:mult_array
            oai_mult m1 (
                .a(wb0_sig[j]),
                .b(wb1_sig[j]),
                .c(rwlb_row0[j]),
                .d(rwlb_row1[j]),
                .e(XINxW[j])
            );
        end

        // 第一级加法树
        for (i = 0; i < 72; i = i + 1) begin
            add #(4) a1
            (
                .s(and1[i]),
                .sus(sus),
                .a(XINxW[2*i]),
                .b(XINxW[2*i+1])
            );
        end

        // 第二级加法树
        for (i = 0; i < 36; i = i + 1) begin
            add #(5) a2
            (
                .s(and2[i]),
                .sus(sus),
                .a(and1[2*i]),
                .b(and1[2*i+1])
            );
        end

        // 第三级加法树
        for (i = 0; i < 18; i = i + 1) begin
            add #(6) a3
            (
                .s(and3[i]),
                .sus(sus),
                .a(and2[2*i]),
                .b(and2[2*i+1])
            );
        end

        // 第四级加法树
        for (i = 0; i < 9; i = i + 1) begin
            add #(7) a4
            (
                .s(and4[i]),
                .sus(sus),
                .a(and3[2*i]),
                .b(and3[2*i+1])
            );
        end

        // 第五级加法树
        for (i = 0; i < 4; i = i + 1) begin
            add #(8) a5
            (
                .s(and5[i]),
                .sus(sus),
                .a(and4[2*i]),
                .b(and4[2*i+1])
            );
        end

        // 第六级加法树
        for (i = 0; i < 2; i = i + 1) begin
            add #(9) a6
            (
                .s(and6[i]),
                .sus(sus),
                .a(and5[2*i]),
                .b(and5[2*i+1])
            );
        end

        // 第七级加法树
        add #(10) a7
        (
            .s(and7[0]),
            .sus(sus),
            .a(and6[1]),
            .b(and6[0])
        );

        // 第八级加法树
        add #(11) a8
        (
            .s(mac_out),
            .sus(sus),
            .a(and7[0]),
            .b(and7[1])
        );

    endgenerate

endmodule

module oai_mult(
    input wire [3:0] a,
    input wire [3:0] b,
    input wire c,
    input wire d,
    output wire [3:0] e
);

    wire [3:0] a1,a2;
    assign a1 = a | {4{c}};
    assign a2 = b | {4{d}};
    assign e = ~ (a1 & a2);

endmodule

module rwldrv(
    input cima,
    input [575:0] xin,
    input clk,rstn,
    input [3:0] sel,
    output reg [143:0] rwlb_row1,
    output reg [143:0] rwlb_row0
);
    wire [143:0] xin_w [3:0];
    
    genvar k;
    generate
        for (k = 0; k < 144; k = k + 1) begin
            assign xin_w[3][k] = xin[4 * k + 3];
            assign xin_w[2][k] = xin[4 * k + 2];
            assign xin_w[1][k] = xin[4 * k + 1];
            assign xin_w[0][k] = xin[4 * k];
        end
    endgenerate

    always @(*) begin
        if(rstn) begin
            if(cima) begin
                // row1 CIM, row0 write in
                rwlb_row0 <= ~144'b0;
                case(sel[1:0]) 
                    2'b00:begin
                        rwlb_row1 = ~xin_w[3];
                    end
                    2'b01:begin
                        rwlb_row1 = ~xin_w[2];
                    end
                    2'b10:begin
                        rwlb_row1 = ~xin_w[1];
                    end
                    2'b11:begin
                        rwlb_row1 = ~xin_w[0];
                    end
                endcase
            end
            else begin
                // row0 CIM, row1 write in
                rwlb_row1 <= ~144'b1;
                case(sel[1:0]) 
                    2'b00:begin
                        rwlb_row0 = ~xin_w[3];
                    end
                    2'b01:begin
                        rwlb_row0 = ~xin_w[2];
                    end
                    2'b10:begin
                        rwlb_row0 = ~xin_w[1];
                    end
                    2'b11:begin
                        rwlb_row0 = ~xin_w[0];
                    end
                endcase
            end
        end
    end
endmodule

module gctrl(
    input [1:0] inwidth,
    input clk,rstn,
    output reg [3:0] sel,
    output reg st
);
    reg [3:0] count;
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
        case(inwidth)
            2'b00:begin
                count = 7;
            end
            2'b01:begin
                count = 11;
            end
            2'b10:begin
                count = 15;
            end
            default:begin
                count = 7;
            end  
        endcase
    end

endmodule