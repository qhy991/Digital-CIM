// `timescale 1ns/1ps

// module accumulator_tb;
//     reg [19:0] in1;
//     reg st, acm_en;
//     reg clk, rstn;
//     wire [35:0] nout;
    
//     // 实例化被测模块
//     accumulator uut (
//         .in1(in1),
//         .st(st),
//         .acm_en(acm_en),
//         .clk(clk),
//         .rstn(rstn),
//         .nout(nout)
//     );
    
//     // 产生时钟信号
//     always #5 clk = ~clk;
    
//     initial begin
//         // 初始化信号
//         clk = 0;
//         rstn = 0;
//         st = 0;
//         acm_en = 1;
//         in1 = 0;
        
//         // 复位
//         #2 rstn = 1;
//         #8
//         $display("Reset released");
        
//         // 第一次输入
//         #5 in1 = 20'h00005; st = 0;
//         $display("Input: %h, Output: %h", in1, nout);
        
//         // 第二次输入
//         #10 in1 = 20'h00010; acm_en = 1; st = 0;
//         $display("Input: %h, Output: %h", in1, nout);
        
//         // 停止累加
//         #11 st = 1;
//         $display("Accumulation stopped, Output: %h", nout);
        
//         // 重新启用累加
//         #10 st = 0; in1 = 20'h00020; acm_en = 1;
//         $display("Input: %h, Output: %h", in1, nout);
        
//         // 复位
//         #19 rstn = 0;
//         $display("Reset asserted, Output: %h", nout);
//         #10 rstn = 1;
//         $display("Reset released, Output: %h", nout);
        
//         // 继续输入
//         #10 in1 = 20'h00015; acm_en = 1; st = 0;
//         $display("Input: %h, Output: %h", in1, nout);
        
//         // 结束仿真
//         #50 $finish;
//     end

//     initial begin
//         $dumpfile("accumulator.vcd");
//         $dumpvars(0);
//     end
    
// endmodule

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
