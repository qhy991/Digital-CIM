module cim_array_old(
    input [23:0] D,
    input [7:0] WA,
    input clk, rstn, cima, 
    output [95:0] wb0_a, wb1_a,
    output [95:0] wb0_b, wb1_b
);
    
    reg [7:0] WA0,WA1;
    reg [23:0] D1;

    cim_bank cim_bank_0 (
        .D(D1),
        .WA(WA0),
        .WB_a(wb0_a),
        .WB_b(wb0_b)
    );
    cim_bank cim_bank_1 (
        .D(D1),
        .WA(WA1),
        .WB_a(wb1_a),
        .WB_b(wb1_b)
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