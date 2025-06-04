module cim_array(
    input [23:0] D1,
    input [7:0] WA0, WA1,
    output [95:0] wb0_a, wb1_a,
    output [95:0] wb0_b, wb1_b
);
    
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

endmodule

