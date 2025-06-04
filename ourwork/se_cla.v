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
    input [26:0] a,
    input [50:0] b,
    output wire [50:0] s
);

    wire [27:0] sm;
    wire [23:0] s1;
    wire [26:0] s2;
    
    s_cla scla1(
        .a({24{a[26]}}),
        .b(b[50:27]),
        .ci(sm[27]),
        .s(s1)
    );
    add #(27) a1(
        .a(a),
        .b(b[26:0]),
        .s(sm),
        .sus(1'b0)
    );
    assign s = {s1,sm[26:0]};

endmodule