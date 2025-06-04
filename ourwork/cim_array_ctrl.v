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