module gctrl(
    input [1:0] inwidth,
    input clk,rstn,
    output reg [3:0] sel,
    output reg st
);
    reg [3:0] count;
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
        case(inwidth)
            2'b00:begin
                count = 7;
            end
            2'b01:begin
                count = 11;
            end
            2'b10:begin
                count = 15;
            end
            default:begin
                count = 7;
            end  
        endcase
    end

endmodule