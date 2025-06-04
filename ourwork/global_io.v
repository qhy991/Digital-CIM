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