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
    input [95:0] wb0,
    input [95:0] wb1,
    input [7:0] rwlb_row1,
    input [7:0] rwlb_row0,
    input sus,
    output wire [14:0] mac_out
);
    wire [11:0] wb0_sig [0:7];
    wire [11:0] wb1_sig [0:7];
    wire [11:0] XINxW [0:7];
    wire [12:0] and1 [0:3];
    wire [13:0] and2 [0:1];

    genvar idx;
    generate
        for (idx = 0; idx < 8; idx = idx + 1) begin
            assign wb0_sig[idx] = wb0[idx*12 +: 12];
            assign wb1_sig[idx] = wb1[idx*12 +: 12];
        end
    endgenerate

    genvar i,j;
    generate
        // 例化OAI乘法器
        for (j = 0; j < 8; j = j + 1) begin:mult_array
            oai_mult m1 (
                .a(wb0_sig[j]),
                .b(wb1_sig[j]),
                .c(rwlb_row0[j]),
                .d(rwlb_row1[j]),
                .e(XINxW[j])
            );
        end

        // 第一级加法树
        for (i = 0; i < 4; i = i + 1) begin
            add #(12) a1
            (
                .s(and1[i]),
                .sus(sus),
                .a(XINxW[2*i]),
                .b(XINxW[2*i+1])
            );
        end

        // 第二级加法树
        for (i = 0; i < 2; i = i + 1) begin
            add #(13) a2
            (
                .s(and2[i]),
                .sus(sus),
                .a(and1[2*i]),
                .b(and1[2*i+1])
            );
        end

        // 第八级加法树
        add #(14) a8
        (
            .s(mac_out),
            .sus(sus),
            .a(and2[0]),
            .b(and2[1])
        );

    endgenerate

endmodule