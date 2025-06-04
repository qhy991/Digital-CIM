// `timescale 1ns / 1ps

// module add_tb;
//     parameter width = 5;

//     // 信号声明
//     reg [width-1:0] a, b;
//     reg sus;
//     wire [width:0] s;
//     wire co;

//     // 实例化被测试模块
//     add #(.width(width)) uut (
//         .a(a),
//         .b(b),
//         .sus(sus),
//         .s(s)
//         // .co(co)
//     );

//     // 任务：打印测试结果
//     task print_result;
//         begin
//             $display("Time = %0t | sus = %b | a = %b (%0d) | b = %b (%0d) | s = %b (%0d) | co = %b",
//                      $time, sus, a, $signed(a), b, $signed(b), s, $signed(s), co);
//         end
//     endtask

//     initial begin
//         // 创建 VCD 波形文件
//         $dumpfile("add_tb.vcd");
//         $dumpvars(0, add_tb);

//         // **测试无符号加法**
//         sus = 0;

//         // Case 1: 3 + 2 = 5
//         a = 5'b00011;  // 3
//         b = 5'b00010;  // 2
//         #10 print_result();

//         // Case 2: 15 + 1 = 16 (产生进位)
//         a = 5'b01111;  // 15
//         b = 5'b00001;  // 1
//         #10 print_result();

//         // Case 3: 10 + 21 = 31 (最大值，无溢出)
//         a = 5'b01010;  // 10
//         b = 5'b10101;  // 21
//         #10 print_result();

//         // **测试有符号加法**
//         sus = 1;

//         // Case 4: -4 + (-4) = -8
//         a = 5'b11100;  // -4
//         b = 5'b11100;  // -4
//         #10 print_result();

//         // Case 5: -8 + 5 = -3
//         a = 5'b11000;  // -8
//         b = 5'b00101;  // 5
//         #10 print_result();

//         // Case 6: 15 + 1 (溢出)
//         a = 5'b01111;  // 15
//         b = 5'b00001;  // 1
//         #10 print_result();

//         // Case 7: -16 + (-1) (溢出)
//         a = 5'b10000;  // -16
//         b = 5'b11111;  // -1
//         #10 print_result();

//         // 测试完成
//         $display("Test completed.");
//         $finish;
//     end
// endmodule

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
