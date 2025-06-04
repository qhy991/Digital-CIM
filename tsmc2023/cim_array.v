module cim_array(
    input [191:0] D,         // 192-bit data input, containing 16 blocks of 12-bit data each
    input [8:0] WA,          // 9-bit one-hot write address
    input clk, rstn, cima, 
    output reg [575:0] wb0_a, wb1_a,
    output reg [575:0] wb0_b, wb1_b,
    output reg [575:0] wb0_c, wb1_c
);
    // Memory arrays, each with a depth of 144 and 12-bit width per cell
    reg [11:0] mem_0 [0:143];  
    reg [11:0] mem_1 [0:143];
    
    integer i, idx;  // Loop variables
    reg [4:0] block_index;  // Decoded block index (0-8)

    always @(posedge clk or negedge rstn) begin
        if (~rstn) begin
            // Reset all memory cells
            for (i = 0; i <= 143; i = i + 1) begin
                mem_0[i] <= 12'b0;
                mem_1[i] <= 12'b0;
            end
        end 
        else begin
            // Split memory content and map to output wbX_Y
            for (i = 0; i <= 143; i = i + 1) begin
                wb1_a[i*4 +: 4] <= ~mem_1[i][3:0];
                wb1_b[i*4 +: 4] <= ~mem_1[i][7:4];
                wb1_c[i*4 +: 4] <= ~mem_1[i][11:8];
                wb0_a[i*4 +: 4] <= ~mem_0[i][3:0];
                wb0_b[i*4 +: 4] <= ~mem_0[i][7:4];
                wb0_c[i*4 +: 4] <= ~mem_0[i][11:8];
            end

            // Decode WA from one-hot encoding to a binary block index
            case(WA)
                9'b000000001: block_index = 0;
                9'b000000010: block_index = 1;
                9'b000000100: block_index = 2;
                9'b000001000: block_index = 3;
                9'b000010000: block_index = 4;
                9'b000100000: block_index = 5;
                9'b001000000: block_index = 6;
                9'b010000000: block_index = 7;
                9'b100000000: block_index = 8;
                default:      block_index = 0;
            endcase

            // valid write
            if (WA != 9'b0) begin
                if (cima) begin
                    for (idx = 0; idx < 16; idx = idx + 1) begin
                        mem_0[block_index * 16 + idx] <= D[idx*12 +: 12];
                    end
                end 
                else begin
                    for (idx = 0; idx < 16; idx = idx + 1) begin
                        mem_1[block_index * 16 + idx] <= D[idx*12 +: 12];
                    end
                end
            end
        end
    end
endmodule