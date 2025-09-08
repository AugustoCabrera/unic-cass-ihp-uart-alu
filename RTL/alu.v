
`timescale 1ns/1ps

// TODO: Add carry bit 

module alu
#(
    parameter NB_DATA = 8,                                  // Data bus width (number of bits for A and B)
    parameter NB_OP = 6                                     // Operation width (number of bits for the operation code)
)
(
    input wire signed [NB_DATA-1 : 0] i_data_a,             // Signed 8-bit number A
    input wire signed [NB_DATA-1 : 0] i_data_b,             // Signed 8-bit number B
    input wire [NB_OP-1 : 0] i_op,                          // Unsigned 6-bit operation code
    output reg signed [NB_DATA-1 : 0] o_alu_result          // Signed 8-bit output
);

    localparam OP_ADD = 6'b100000;                          // ADD operation
    localparam OP_SUB = 6'b100010;                          // SUB operation
    localparam OP_AND = 6'b100100;                          // AND operation
    localparam OP_OR  = 6'b100101;                          // OR operation
    localparam OP_XOR = 6'b100110;                          // XOR operation
    localparam OP_SRA = 6'b000011;                          // SRA (arithmetic shift right)
    localparam OP_SRL = 6'b000010;                          // SRL (logical shift right)
    localparam OP_NOR = 6'b100111;                          // NOR operation

    // Combinational block, it will trigger every time any of the inputs change.
    always @(*)
    begin
        case (i_op)
            OP_ADD: o_alu_result = i_data_a + i_data_b;           // With signed numbers addition is two's complement.
            OP_SUB: o_alu_result = i_data_a - i_data_b;           // With signed numbers subtraction is two's complement.
            OP_AND: o_alu_result = i_data_a & i_data_b;
            OP_OR:  o_alu_result = i_data_a | i_data_b;
            OP_XOR: o_alu_result = i_data_a ^ i_data_b;
            OP_SRA: o_alu_result = i_data_a >>> i_data_b;
            OP_SRL: o_alu_result = i_data_a >> i_data_b;
            OP_NOR: o_alu_result = ~(i_data_a | i_data_b);
            default: o_alu_result = 0;
        endcase
    end

endmodule