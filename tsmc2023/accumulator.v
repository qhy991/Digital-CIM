`timescale 1ns/1ps

module accumulator_tb;
    reg [19:0] in1;
    reg st, acm_en;
    reg clk, rstn;
    wire [35:0] nout;
    
    // 实例化被测模块
    accumulator uut (
        .in1(in1),
        .st(st),
        .acm_en(acm_en),
        .clk(clk),
        .rstn(rstn),
        .nout(nout)
    );
    
    // 产生时钟信号
    always #5 clk = ~clk;
    
    initial begin
        // 初始化信号
        clk = 0;
        rstn = 0;
        st = 0;
        acm_en = 1;
        in1 = 0;
        
        // 复位
        #2 rstn = 1;
        #8
        $display("Reset released");
        
        // 第一次输入
        #5 in1 = 20'h00005; st = 0;
        $display("Input: %h, Output: %h", in1, nout);
        
        // 第二次输入
        #10 in1 = 20'h00010; acm_en = 1; st = 0;
        $display("Input: %h, Output: %h", in1, nout);
        
        // 停止累加
        #11 st = 1;
        $display("Accumulation stopped, Output: %h", nout);
        
        // 重新启用累加
        #10 st = 0; in1 = 20'h00020; acm_en = 1;
        $display("Input: %h, Output: %h", in1, nout);
        
        // 复位
        #19 rstn = 0;
        $display("Reset asserted, Output: %h", nout);
        #10 rstn = 1;
        $display("Reset released, Output: %h", nout);
        
        // 继续输入
        #10 in1 = 20'h00015; acm_en = 1; st = 0;
        $display("Input: %h, Output: %h", in1, nout);
        
        // 结束仿真
        #50 $finish;
    end

    initial begin
        $dumpfile("accumulator.vcd");
        $dumpvars(0);
    end
    
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