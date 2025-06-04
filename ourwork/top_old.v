module top(
    input [23:0] D,
    input clk,rstn,cima,acm_en,
    input [7:0] WA,
    input inwidth,
    input wwidth,
    input [95:0] xin0,
    output [50:0] nout,
    output wire st
);
    wire [14:0] macout_a,macout_b;
    wire [95:0] wb0_a,wb1_a,wb0_b,wb1_b;
    wire [7:0] rwlb_row1,rwlb_row0;
    wire [5:0] sel;
    wire [23:0] D1;
    wire [7:0] WA0, WA1;

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

    cim_array cim_array_u(
        .D1(D1),
        .WA0(WA0),
        .WA1(WA1),
        .wb0_a(wb0_a),
        .wb1_a(wb1_a),
        .wb0_b(wb0_b),
        .wb1_b(wb1_b)
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