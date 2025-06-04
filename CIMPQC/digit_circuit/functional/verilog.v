//Verilog HDL for "CIMPQC", "digit_circuit" "functional"

module digit_circuit(
    input [23:0] D,
    input clk,rstn,cima,acm_en,
    input [7:0] WA,
    input inwidth,
    input wwidth,
    input [95:0] xin0,
    input wire [95:0] wb0_a,wb1_a,wb0_b,wb1_b,
    output [50:0] nout,
    output wire st,
    output wire [7:0] WA0, WA1,
    output wire [23:0] D1
);  
    wire [14:0] macout_a,macout_b;
    wire [7:0] rwlb_row1,rwlb_row0;
    wire [5:0] sel;
    
    global_io global_io_u(
        .macout_a(macout_a),
        .macout_b(macout_b),
        .clk(clk),
        .acm_en(acm_en),
        .rstn(rstn),
        .st(st),
        .wwidth(wwidth),
        .nout(nout)
    );

    cim_array_ctrl cim_array_ctrl_u(
        .D(D),
        .WA(WA),
        .clk(clk),
        .rstn(rstn),
        .cima(cima),
        .D1(D1),
        .WA0(WA0),
        .WA1(WA1)
    );

    local_mac lmaca(
        .wb0(wb0_a),
        .wb1(wb1_a),
        .rwlb_row1(rwlb_row1),
        .rwlb_row0(rwlb_row0),
        .sus(1'b0),
        .mac_out(macout_a)
    );

    local_mac lmacb(
        .wb0(wb0_b),
        .wb1(wb1_b),
        .rwlb_row1(rwlb_row1),
        .rwlb_row0(rwlb_row0),
        .sus(~wwidth),
        .mac_out(macout_b)
    );

    rwldrv rwldrv_u(
        .cima(cima),
        .xin(xin0),
        .clk(clk),
        .rstn(rstn),
        .sel(sel),
        .rwlb_row1(rwlb_row1),
        .rwlb_row0(rwlb_row0)
    );

    gctrl gctrl_u(
        .inwidth(inwidth),
        .clk(clk),
        .rstn(rstn),
        .sel(sel),
        .st(st)
    );

endmodule

module global_io(
    input [14:0] macout_a,
    input [14:0] macout_b,
    input clk,acm_en,rstn,
    input st,
    input wwidth,
    output [50:0] nout
);
    // DFF
    reg [14:0] in_a;
    reg [26:0] in_b;

    wire [26:0] c1;
    wire [27:0] out;

    always @(posedge clk) begin
        in_a <= macout_a;
        in_b <= macout_b << 12;
    end

    assign c1 = ~(in_b | ~{27{wwidth}});

    add #(27) a2
    (
        .a({12'b0,in_a}),
        .b(c1),
        .sus(1'b1),
        .s(out)
    );

    accumulator acc1
    (
        .in1(out[26:0]),
        .st(st),
        .acm_en(acm_en),
        .clk(clk),
        .rstn(rstn),
        .nout(nout)
    );
    
endmodule

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

module add # (parameter width = 5)
(
    input wire [width-1:0] a,
    input wire [width-1:0] b,
    input wire sus,  // sus = 1: , sus = 0: 
    output reg [width:0] s  //  1 
);
    always @(*) begin
        if (sus) begin
            // 
            s = {a[width-1], a} + {b[width-1], b};
        end else begin
            //  0
            s = {1'b0, a} + {1'b0, b};
        end
    end
endmodule

module s_cla(
    input signed [23:0] a,
    input signed [23:0] b,
    input ci,
    output signed [23:0] s,
    output co
);
    wire [23:0] G;  // 
    wire [23:0] P;  // 
    wire [23:0] C;  // 

    // 
    assign G = a & b;
    assign P = a ^ b;

    // 
    assign C[0] = ci;
    genvar i;
    generate
        for (i = 1; i < 24; i = i + 1) begin
            assign C[i] = G[i-1] | (P[i-1] & C[i-1]);
        end
    endgenerate

    // 
    assign s = P ^ C;

    // 
    assign co = G[23] | (P[23] & C[23]);

endmodule

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
        // OAI
        for (j = 0; j < 8; j = j + 1) begin:mult_array
            oai_mult m1 (
                .a(wb0_sig[j]),
                .b(wb1_sig[j]),
                .c(rwlb_row0[j]),
                .d(rwlb_row1[j]),
                .e(XINxW[j])
            );
        end

        // 
        for (i = 0; i < 4; i = i + 1) begin
            add #(12) a1
            (
                .s(and1[i]),
                .sus(sus),
                .a(XINxW[2*i]),
                .b(XINxW[2*i+1])
            );
        end

        // 
        for (i = 0; i < 2; i = i + 1) begin
            add #(13) a2
            (
                .s(and2[i]),
                .sus(sus),
                .a(and1[2*i]),
                .b(and1[2*i+1])
            );
        end

        // 
        add #(14) a8
        (
            .s(mac_out),
            .sus(sus),
            .a(and2[0]),
            .b(and2[1])
        );

    endgenerate

endmodule

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
                rwlb_row0 <= ~8'b0;
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
                rwlb_row1 <= ~8'b0;
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

module gctrl(
    input inwidth,
    input clk,rstn,
    output reg [5:0] sel,
    output reg st
);
    reg [5:0] count;
    always @(posedge clk,negedge rstn) begin
        if(~rstn) begin
            sel <= 0;
            st <= 1'b1;
        end
        else begin
            if(sel < count) begin
                sel <= sel + 1;
                st <= 1'b0;
            end
            else begin
                sel <= 0;
                st <= 1'b1;
            end
        end
    end
    always @(*) begin
        count = (inwidth)? 6'd23: 6'd11;
    end
endmodule

module cim_array_ctrl(
    input [23:0] D,
    input [7:0] WA,
    input clk, rstn, cima, 
    output reg [23:0] D1,
    output reg [7:0] WA0, WA1
);
    
    integer i, idx;  // Loop variables
    reg [3:0] block_index;  // Decoded block index (0-8)

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            WA0 <= ~8'b0;
            WA1 <= ~8'b0;
            D1 <= 24'b0;
        end 
        else begin
            if (WA != 8'b0) begin
                D1 <= D;
                if (cima) begin
                    WA0 <= WA[7:0];
                    WA1 <= 8'b0;
                end 
                else begin
                    WA1 <= WA[7:0];
                    WA0 <= 8'b0;
                end
            end
        end
    end

endmodule
