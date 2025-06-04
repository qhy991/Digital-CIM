// module oai_mult_tb();
//     reg [3:0] a, b;
//     reg c, d;
//     wire [3:0] e;

//     oai_mult uut(
//         .a(a),
//         .b(b),
//         .c(c),
//         .d(d),
//         .e(e)
//     );

//     initial begin
//         a = 4'b0110;
//         b = 4'b0001;
//         c = 1'b0;
//         d = 1'b1;
//         #10;
//         $display("e = %b", e);
//         $finish;
//     end

// endmodule

// OAI乘法器
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