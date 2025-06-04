module cim_bank(
    input [23:0] D,
    input [7:0] WA,
    output reg [95:0] WB_a, WB_b
);
    reg [23:0] mem [0:7];
    always @(*) begin
        case(WA)
            8'b00000001: begin
                mem[0] = D;
            end
            8'b00000010: begin
                mem[1] = D;
            end
            8'b00000100: begin
                mem[2] = D;
            end
            8'b00001000: begin
                mem[3] = D;
            end
            8'b00010000: begin
                mem[4] = D;
            end
            8'b00100000: begin
                mem[5] = D;
            end
            8'b01000000: begin
                mem[6] = D;
            end
            8'b10000000: begin
                mem[7] = D;
            end
            default: begin
                mem[0] = D;
            end
        endcase
        WB_a = {~mem[7][11:0], ~mem[6][11:0], ~mem[5][11:0], ~mem[4][11:0], ~mem[3][11:0], ~mem[2][11:0], ~mem[1][11:0], ~mem[0][11:0]};
        WB_b = {~mem[7][23:12], ~mem[6][23:12], ~mem[5][23:12], ~mem[4][23:12], ~mem[3][23:12], ~mem[2][23:12], ~mem[1][23:12], ~mem[0][23:12]};
    end
endmodule