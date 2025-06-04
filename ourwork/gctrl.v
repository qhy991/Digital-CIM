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