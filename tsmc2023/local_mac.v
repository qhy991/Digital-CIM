// `timescale 1ns / 1ps
// module local_mac_tb();
//     reg [575:0] wb0;
//     reg [575:0] wb1;
//     reg [143:0] rwlb_row1;
//     reg [143:0] rwlb_row0;
//     wire [11:0] mac_out;

//     local_mac mac (
//         .wb0(wb0),
//         .wb1(wb1),
//         .rwlb_row1(rwlb_row1),
//         .rwlb_row0(rwlb_row0),
//         .mac_out(mac_out)
//     );

//     initial begin
//         wb1 = ~576'b0;
//         rwlb_row1 = ~144'b0;
//         wb0 = ~(~576'b0);
//         rwlb_row0 = ~(~144'b0);
//         #10;
//         $display("mac_out = %d", mac_out);
//         #10;
//         wb1 = ~576'b0;
//         rwlb_row1 = ~144'b0;
//         wb0 = ~576'b1111;
//         rwlb_row0 = ~144'b1;
//         #10;
//         $display("mac_out = %d", mac_out);
//         $finish;
//     end

//     initial begin
//         $dumpfile("local_mac_tb.vcd");
//         $dumpvars(0);
//     end

// endmodule

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