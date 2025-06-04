// module tb_rwldrv();
//     reg cima;
//     reg [575:0] xin;
//     reg clk, rstn;
//     reg [3:0] sel;
//     wire [143:0] rwlb_row1, rwlb_row0;

//     // 实例化被测模块
//     rwldrv uut (
//         .cima(cima),
//         .xin(xin),
//         .clk(clk),
//         .rstn(rstn),
//         .sel(sel),
//         .rwlb_row1(rwlb_row1),
//         .rwlb_row0(rwlb_row0)
//     );

//     // 生成时钟信号（周期10ns）
//     initial begin
//         clk = 0;
//         forever #5 clk = ~clk;
//     end

//     // 测试流程
//     initial begin
//         // 初始化信号
//         rstn = 0;
//         cima = 1;
//         sel = 0;
//         xin = 0;
//         #10;  // 保持复位状态

//         // 测试1：释放复位
//         rstn = 1;
//         #10;

//         // 测试2：cima=1，测试sel选择不同xin_w段
//         xin = 576'h1234_5678_9ABC_DEF0;  // 示例数据
        
//         // sel=00，选择xin_w[3]（xin[15:12] = 0xF0的高4位即0xF）
//         sel = 2'b00;
//         $display("Time=%t: cima=%b | sel=%b | xin_w[sel]=%h | row1=...%h | row0=...%h",
//                  $time, cima, sel[1:0],
//                  uut.xin_w[{sel[1:0], 2'b00} + 3],  // 获取xin_w[sel]
//                  rwlb_row1[3:0],  // 显示低4位
//                  rwlb_row0[3:0]);
//         #10;

//         sel = 2'b01;
//         $display("Time=%t: cima=%b | sel=%b | xin_w[sel]=%h | row1=...%h | row0=...%h",
//                  $time, cima, sel[1:0],
//                  uut.xin_w[{sel[1:0], 2'b00} + 3],  // 获取xin_w[sel]
//                  rwlb_row1[3:0],  // 显示低4位
//                  rwlb_row0[3:0]);
//         #10;

//         sel = 2'b10;
//         $display("Time=%t: cima=%b | sel=%b | xin_w[sel]=%h | row1=...%h | row0=...%h",
//                  $time, cima, sel[1:0],
//                  uut.xin_w[{sel[1:0], 2'b00} + 3],  // 获取xin_w[sel]
//                  rwlb_row1[3:0],  // 显示低4位
//                  rwlb_row0[3:0]);
//         #10;

//         sel = 2'b11;
//         $display("Time=%t: cima=%b | sel=%b | xin_w[sel]=%h | row1=...%h | row0=...%h",
//                  $time, cima, sel[1:0],
//                  uut.xin_w[{sel[1:0], 2'b00} + 3],  // 获取xin_w[sel]
//                  rwlb_row1[3:0],  // 显示低4位
//                  rwlb_row0[3:0]);
//         #10;

//         xin = 576'hFFFF_0000_FFFF_0000;  // 新测试数据

//         sel = 2'b00;
//         #10;

//         sel = 2'b01;
//         #10;

//         $finish;
//     end

//     initial begin
//         $dumpfile("rwldrv.vcd");
//         $dumpvars(0);
//     end

// endmodule

module rwldrv(
    input cima,
    input [95:0] xin,
    input clk,rstn,
    input [5:0] sel,
    output reg [7:0] rwlb_row1,
    output reg [7:0] rwlb_row0
);
    wire [7:0] xin_w [11:0];
    
    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin
            assign xin_w[11][k] = xin[12 * k + 11];
            assign xin_w[10][k] = xin[12 * k + 10];
            assign xin_w[9][k] = xin[12 * k + 9];
            assign xin_w[8][k] = xin[12 * k + 8];
            assign xin_w[7][k] = xin[12 * k + 7];
            assign xin_w[6][k] = xin[12 * k + 6];
            assign xin_w[5][k] = xin[12 * k + 5];
            assign xin_w[4][k] = xin[12 * k + 4];
            assign xin_w[3][k] = xin[12 * k + 3];
            assign xin_w[2][k] = xin[12 * k + 2];
            assign xin_w[1][k] = xin[12 * k + 1];
            assign xin_w[0][k] = xin[12 * k + 0];
        end
    endgenerate

    always @(*) begin
        if(rstn) begin
            if(cima) begin
                // row1 CIM, row0 write in
                rwlb_row0 = ~8'b0;
                case(sel) 
                    6'd0:begin
                        rwlb_row1 = ~xin_w[11];
                    end
                    6'd1:begin
                        rwlb_row1 = ~xin_w[10];
                    end
                    6'd2:begin
                        rwlb_row1 = ~xin_w[9];
                    end
                    6'd3:begin
                        rwlb_row1 = ~xin_w[8];
                    end
                    6'd4:begin
                        rwlb_row1 = ~xin_w[7];
                    end
                    6'd5:begin
                        rwlb_row1 = ~xin_w[6];
                    end
                    6'd6:begin
                        rwlb_row1 = ~xin_w[5];
                    end
                    6'd7:begin
                        rwlb_row1 = ~xin_w[4];
                    end
                    6'd8:begin
                        rwlb_row1 = ~xin_w[3];
                    end
                    6'd9:begin
                        rwlb_row1 = ~xin_w[2];
                    end
                    6'd10:begin
                        rwlb_row1 = ~xin_w[1];
                    end
                    6'd11:begin
                        rwlb_row1 = ~xin_w[0];
                    end
                    6'd12:begin
                        rwlb_row1 = ~xin_w[11];
                    end
                    6'd13:begin
                        rwlb_row1 = ~xin_w[10];
                    end
                    6'd14:begin
                        rwlb_row1 = ~xin_w[9];
                    end
                    6'd15:begin
                        rwlb_row1 = ~xin_w[8];
                    end
                    6'd16:begin
                        rwlb_row1 = ~xin_w[7];
                    end
                    6'd17:begin
                        rwlb_row1 = ~xin_w[6];
                    end
                    6'd18:begin
                        rwlb_row1 = ~xin_w[5];
                    end
                    6'd19:begin
                        rwlb_row1 = ~xin_w[4];
                    end
                    6'd20:begin
                        rwlb_row1 = ~xin_w[3];
                    end
                    6'd21:begin
                        rwlb_row1 = ~xin_w[2];
                    end
                    6'd22:begin
                        rwlb_row1 = ~xin_w[1];
                    end
                    6'd23:begin
                        rwlb_row1 = ~xin_w[0];
                    end
                endcase
            end
            else begin
                // row0 CIM, row1 write in
                rwlb_row1 = ~8'b0;
                case(sel[1:0]) 
                    6'd0:begin
                        rwlb_row0 = ~xin_w[11];
                    end
                    6'd1:begin
                        rwlb_row0 = ~xin_w[10];
                    end
                    6'd2:begin
                        rwlb_row0 = ~xin_w[9];
                    end
                    6'd3:begin
                        rwlb_row0 = ~xin_w[8];
                    end
                    6'd4:begin
                        rwlb_row0 = ~xin_w[7];
                    end
                    6'd5:begin
                        rwlb_row0 = ~xin_w[6];
                    end
                    6'd6:begin
                        rwlb_row0 = ~xin_w[5];
                    end
                    6'd7:begin
                        rwlb_row0 = ~xin_w[4];
                    end
                    6'd8:begin
                        rwlb_row0 = ~xin_w[3];
                    end
                    6'd9:begin
                        rwlb_row0 = ~xin_w[2];
                    end
                    6'd10:begin
                        rwlb_row0 = ~xin_w[1];
                    end
                    6'd11:begin
                        rwlb_row0 = ~xin_w[0];
                    end
                    6'd12:begin
                        rwlb_row0 = ~xin_w[11];
                    end
                    6'd13:begin
                        rwlb_row0 = ~xin_w[10];
                    end
                    6'd14:begin
                        rwlb_row0 = ~xin_w[9];
                    end
                    6'd15:begin
                        rwlb_row0 = ~xin_w[8];
                    end
                    6'd16:begin
                        rwlb_row0 = ~xin_w[7];
                    end
                    6'd17:begin
                        rwlb_row0 = ~xin_w[6];
                    end
                    6'd18:begin
                        rwlb_row0 = ~xin_w[5];
                    end
                    6'd19:begin
                        rwlb_row0 = ~xin_w[4];
                    end
                    6'd20:begin
                        rwlb_row0 = ~xin_w[3];
                    end
                    6'd21:begin
                        rwlb_row0 = ~xin_w[2];
                    end
                    6'd22:begin
                        rwlb_row0 = ~xin_w[1];
                    end
                    6'd23:begin
                        rwlb_row0 = ~xin_w[0];
                    end
                endcase
            end
        end
    end
endmodule