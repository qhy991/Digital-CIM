//Verilog HDL for "CIMPQC", "csdrv" "functional"

module csdrv (
    input wire [15:0] cs,
    input wire [7:0] WA0,
    output reg [127:0] WA
);
    always@(*) begin
        WA[7:0] = {8{cs[0]}} & WA0; 
        WA[15:8] = {8{cs[1]}} & WA0; 
        WA[23:16] = {8{cs[2]}} & WA0; 
        WA[31:24] = {8{cs[3]}} & WA0; 
        WA[39:32] = {8{cs[4]}} & WA0; 
        WA[47:40] = {8{cs[5]}} & WA0; 
        WA[55:48] = {8{cs[6]}} & WA0; 
        WA[63:56] = {8{cs[7]}} & WA0; 
        WA[71:64] = {8{cs[8]}} & WA0; 
        WA[79:72] = {8{cs[9]}} & WA0; 
        WA[87:80] = {8{cs[10]}} & WA0; 
        WA[95:88] = {8{cs[11]}} & WA0; 
        WA[103:96] = {8{cs[12]}} & WA0; 
        WA[111:104] = {8{cs[13]}} & WA0; 
        WA[119:112] = {8{cs[14]}} & WA0; 
        WA[127:120] = {8{cs[15]}} & WA0; 
    end

endmodule
