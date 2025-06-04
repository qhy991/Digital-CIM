module s_cla(
    input signed [23:0] a,
    input signed [23:0] b,
    input ci,
    output signed [23:0] s,
    output co
);
    wire [23:0] G;  // 生成信号
    wire [23:0] P;  // 传播信号
    wire [23:0] C;  // 进位信号

    // 生成和传播信号
    assign G = a & b;
    assign P = a ^ b;

    // 计算进位
    assign C[0] = ci;
    genvar i;
    generate
        for (i = 1; i < 24; i = i + 1) begin
            assign C[i] = G[i-1] | (P[i-1] & C[i-1]);
        end
    endgenerate

    // 计算和
    assign s = P ^ C;

    // 计算无符号进位输出
    assign co = G[23] | (P[23] & C[23]);

endmodule