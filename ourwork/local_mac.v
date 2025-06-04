// `timescale 1ns / 1ps
// module local_mac_tb();
//     reg [575:0] wb0;
//     reg [575:0] wb1;
//     reg [143:0] rwlb_row1;
//     reg [143:0] rwlb_row0;
//     wire [11:0] mac_out;

//     local_mac mac (
//         .wb0(wb0),
//         .wb1(wb1),
//         .rwlb_row1(rwlb_row1),
//         .rwlb_row0(rwlb_row0),
//         .mac_out(mac_out)
//     );

//     initial begin
//         wb1 = ~576'b0;
//         rwlb_row1 = ~144'b0;
//         wb0 = ~(~576'b0);
//         rwlb_row0 = ~(~144'b0);
//         #10;
//         $display("mac_out = %d", mac_out);
//         #10;
//         wb1 = ~576'b0;
//         rwlb_row1 = ~144'b0;
//         wb0 = ~576'b1111;
//         rwlb_row0 = ~144'b1;
//         #10;
//         $display("mac_out = %d", mac_out);
//         $finish;
//     end

//     initial begin
//         $dumpfile("local_mac_tb.vcd");
//         $dumpvars(0);
//     end

// endmodule

// local_mac: Performs Multiply-Accumulate (MAC) or Fused Multiply-Add-Subtract (FMAS) operations.
// The core "multiplication" is a sum of 8 oai_mult results, followed by an optional addition (C_in)
// and an optional subtraction (D_in).
module local_mac(
    // Standard inputs from original design
    input [95:0] wb0,             // Input data array 0
    input [95:0] wb1,             // Input data array 1
    input [7:0] rwlb_row1,        // Control signals for oai_mult
    input [7:0] rwlb_row0,        // Control signals for oai_mult
    input sus,                    // Suspect signal, possibly for signed/unsigned control in adders

    // New inputs for FMAS functionality
    input wire [11:0] C_in,       // Addend for MAC operation ((A*B) + C_in)
                                  // and for FMAS operation ((A*B) + C_in - D_in)
    input wire [11:0] D_in,       // Subtrahend for FMAS operation ((A*B) + C_in - D_in), used when op_sel = 1
    input wire op_sel,          // Operation select:
                                  //   0 for MAC: (sum of oai_mults) + C_in
                                  //   1 for FMAS: (sum of oai_mults) + C_in - D_in
    // Output port
    output wire [13:0] result_out // Result of MAC/FMAS operation (14 bits wide, formerly mac_out [14:0])
);
    // Internal wires for processing pipeline
    wire [11:0] wb0_sig [0:7];    // 12-bit segments from wb0
    wire [11:0] wb1_sig [0:7];    // 12-bit segments from wb1
    wire [11:0] XINxW [0:7];      // Output of oai_mult instances
    wire [12:0] and1 [0:3];       // Output of first stage adders
    wire [13:0] and2 [0:1];       // Output of second stage adders

    // Internal wire for the sum of products (result of the original MAC adder tree)
    wire [14:0] current_mac_sum;
    // Intermediate result for (current_mac_sum) + C_in
    wire [15:0] add_c_result;
    // Intermediate result for ((current_mac_sum) + C_in) - D_in
    wire [15:0] sub_d_result;

    // Generate 12-bit segments from 96-bit inputs wb0 and wb1
    genvar idx;
    generate
        for (idx = 0; idx < 8; idx = idx + 1) begin
            assign wb0_sig[idx] = wb0[idx*12 +: 12];
            assign wb1_sig[idx] = wb1[idx*12 +: 12];
        end
    endgenerate

    // Generate oai_mult array and adder tree
    genvar i,j;
    generate
        // Instantiate 8 oai_mult units
        // 例化OAI乘法器 (Instantiate OAI Multiplier)
        for (j = 0; j < 8; j = j + 1) begin:mult_array
            oai_mult m1 (
                .a(wb0_sig[j]),
                .b(wb1_sig[j]),
                .c(rwlb_row0[j]),
                .d(rwlb_row1[j]),
                .e(XINxW[j])
            );
        end

        // First stage of adder tree (4 adders)
        // 第一级加法树 (First level adder tree)
        for (i = 0; i < 4; i = i + 1) begin
            add #(12) a1 // Adder for 12-bit inputs, output is 13-bit
            (
                .s(and1[i]),
                .sus(sus),
                .a(XINxW[2*i]),
                .b(XINxW[2*i+1])
            );
        end

        // Second stage of adder tree (2 adders)
        // 第二级加法树 (Second level adder tree)
        for (i = 0; i < 2; i = i + 1) begin
            add #(13) a2 // Adder for 13-bit inputs, output is 14-bit
            (
                .s(and2[i]),
                .sus(sus),
                .a(and1[2*i]),
                .b(and1[2*i+1])
            );
        end

        // Final adder in the tree, outputting the sum of all oai_mult products
        // 第八级加法树 (Eighth level adder tree - actually 3rd stage, final sum)
        add #(14) a8 // Adder for 14-bit inputs, output is 15-bit
        (
            .s(current_mac_sum), // Output to internal wire current_mac_sum
            .sus(sus),
            .a(and2[0]),
            .b(and2[1])
        );
    endgenerate

    // Combinational logic for MAC and FMAS operations using the current_mac_sum
    // Calculate (A*B) + C (where A*B is current_mac_sum)
    assign add_c_result = current_mac_sum + C_in;
    // Calculate ((A*B) + C) - D
    assign sub_d_result = add_c_result - D_in;

    // Select operation based on op_sel:
    // If op_sel = 1, perform FMAS: (current_mac_sum + C_in - D_in)
    // If op_sel = 0, perform MAC:  (current_mac_sum + C_in)
    // Assign to output, truncating/selecting the lower 14 bits.
    assign result_out = op_sel ? sub_d_result[13:0] : add_c_result[13:0];

endmodule
