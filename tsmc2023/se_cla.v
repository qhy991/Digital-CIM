// `timescale 1ns / 1ps

// module tb_se_cla;

//     // 输入信号
//     reg signed [19:0] a;  // 20位有符号数
//     reg signed [35:0] b;  // 36位有符号数
    
//     // 输出信号
//     wire signed [35:0] s; // 36位有符号结果
    
//     // 实例化被测模块
//     se_cla uut (
//         .a(a),
//         .b(b),
//         .s(s)
//     );
    
//     initial begin

//         // 测试用例 1：两个正数相加
//         a = 20'sd100_000;
//         b = 36'sd500_000;
//         #10 print_result();
        
//         // 测试用例 2：一个正数加一个负数
//         a = 20'sd300_000;  // 300000
//         b = -36'sd200_000; // -200000
//         #10 print_result();

//         // 测试用例 3：两个负数相加
//         a = -20'sd250_000;
//         b = -36'sd600_000;
//         #10 print_result();

//         // 测试用例 4：a 为 0
//         a = 20'sd0;
//         b = 36'sd123456;
//         #10 print_result();

//         // 测试用例 5：b 为 0
//         a = 20'sd654321;
//         b = 36'sd0;
//         #10 print_result();

//         // 测试用例 6：最大正数 + 1
//         a = 20'sd524287;  // 20 位最大正数 (2^19 - 1)
//         b = 36'sd1;
//         #10 print_result();

//         // 测试用例 7：最小负数 + 负数
//         a = -20'sd524288;  // 20 位最小负数 (-2^19)
//         b = -36'sd10;
//         #10 print_result();

//         // 测试结束
//         $finish;
//     end

//     task print_result;
//         begin
//             $display("Time=%0t | a=%d | b=%d | s=%d", $time, $signed(a), $signed(b), $signed(s));
//         end
//     endtask

// endmodule

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