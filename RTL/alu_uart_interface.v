// ALU UART Interface Module
// This module interfaces between an ALU and a UART, handling commands and results.
// Parameters:
// - NB_DATA: Width of the data bus (number of bits in the data).
// - NB_OPCODE: Width of the opcode (number of bits used for operation codes).

`timescale 1ns/1ps


module alu_uart_interface #(
    parameter NB_DATA = 8,                              // Data width
    parameter NB_OPCODE = 6                             // Opcode width
)
(
    input wire i_clk,                                   // Input clock signal
    input wire i_reset,                                 // Asynchronous reset signal
    input wire [NB_DATA-1:0] i_alu_result,              // Result from the ALU
    input wire [NB_DATA-1:0] i_data_to_read,            // Data read from FIFO
    input wire i_fifo_rx_empty,                         // FIFO RX empty signal
    input wire i_fifo_tx_full,                          // FIFO TX full signal

    output wire o_fifo_rx_read,                         // Signal to read from FIFO RX
    output wire o_fifo_tx_write,                        // Signal to write to FIFO TX
    output wire [NB_DATA-1:0] o_data_to_write,          // Data to be written to FIFO TX
    output wire [NB_OPCODE-1:0] o_alu_opcode,           // Opcode for the ALU
    output wire [NB_DATA-1:0] o_alu_op_A,               // Operand A for the ALU
    output wire [NB_DATA-1:0] o_alu_op_B               // Operand B for the ALU
);

localparam [3:0] IDLE = 4'b0000;                        // Idle state
localparam [3:0] OPCODE = 4'b0001;                      // Opcode state
localparam [3:0] OPERAND_A = 4'b0010;                   // Operand A state
localparam [3:0] OPERAND_B = 4'b0011;                   // Operand B state
localparam [3:0] RESULT = 4'b0100;                      // Result state
localparam [3:0] WAIT = 4'b1000;                        // Wait state

// State and register definitions
reg [3:0] state, state_next;                            // Current and next state
reg fifo_rx_read, fifo_rx_read_next;                    // FIFO RX read control signal
reg fifo_tx_write, fifo_tx_write_next;                  // FIFO TX write control signal
reg [NB_OPCODE-1:0] opcode_sel, opcode_sel_next;        // Selected opcode
reg [NB_DATA-1:0] operand_a_sel, operand_a_sel_next;    // Selected Operand A
reg [NB_DATA-1:0] operand_b_sel, operand_b_sel_next;    // Selected Operand B
reg [NB_DATA-1:0] result, result_next;                  // Result from ALU
reg [3:0] wait_reg, wait_next;                          // Wait register

// Synchronous process: Update state and registers on the rising edge of the clock
always @(posedge i_clk) begin
    if(i_reset) begin
        // Reset state and registers to initial values
        state           <= IDLE;
        fifo_rx_read    <= 1'b0;
        fifo_tx_write   <= 1'b0;
        opcode_sel      <= {NB_OPCODE{1'b0}};
        operand_a_sel   <= {NB_DATA{1'b0}};
        operand_b_sel   <= {NB_DATA{1'b0}};
        result          <= {NB_DATA{1'b0}};
        wait_reg        <= 4'b0000;
    end
    else begin
        // Update state and registers with the next values
        state           <= state_next;
        fifo_rx_read    <= fifo_rx_read_next;
        fifo_tx_write   <= fifo_tx_write_next;
        opcode_sel      <= opcode_sel_next;
        operand_a_sel   <= operand_a_sel_next;
        operand_b_sel   <= operand_b_sel_next;
        result          <= result_next;
        wait_reg        <= wait_next;
    end
end

// Combinational process: Determine next state and output values based on current state
always @(*) begin
    // Default assignments
    state_next          = state;
    fifo_rx_read_next   = fifo_rx_read;
    fifo_tx_write_next  = fifo_tx_write;
    opcode_sel_next     = opcode_sel;
    operand_a_sel_next  = operand_a_sel;
    operand_b_sel_next  = operand_b_sel;
    result_next         = result;
    wait_next           = wait_reg;

    // State machine for ALU UART interface
    case (state)
        IDLE: begin
            fifo_tx_write_next = 1'b0;    
            if (~i_fifo_rx_empty) begin
                // If FIFO RX is not empty, read the opcode
                state_next          = OPCODE;
                fifo_rx_read_next   = 1'b1;
            end
        end
        
        WAIT: begin
            // Wait state to ensure proper reading from FIFO
            if (~i_fifo_rx_empty) begin
                state_next          = wait_reg;     // Go back to the saved wait state
                fifo_rx_read_next   = 1'b1;
            end
        end
        
        OPCODE: begin
            if (i_fifo_rx_empty) begin
                // If FIFO RX is empty, switch to WAIT state
                fifo_rx_read_next   = 1'b0;
                state_next          = WAIT;
                wait_next           = OPCODE;       // Save current state
            end
            else begin
                // Read opcode from FIFO
                state_next          = OPERAND_A;
                opcode_sel_next     = i_data_to_read[NB_OPCODE-1:0];
                fifo_rx_read_next   = 1'b1;         // Continue reading
            end
        end 

        OPERAND_A: begin
            if (i_fifo_rx_empty) begin
                // If FIFO RX is empty, switch to WAIT state
                fifo_rx_read_next   = 1'b0;
                state_next          = WAIT;
                wait_next           = OPERAND_A;    // Save current state
            end
            else begin
                // Read Operand A from FIFO
                state_next          = OPERAND_B;
                operand_a_sel_next  = i_data_to_read;
                fifo_rx_read_next   = 1'b1;         // Continue reading
            end
        end

        OPERAND_B: begin
            if (i_fifo_rx_empty) begin
                // If FIFO RX is empty, switch to WAIT state
                fifo_rx_read_next   = 1'b0;
                state_next          = WAIT;
                wait_next           = OPERAND_B;    // Save current state
            end
            else begin
                // Read Operand B from FIFO
                state_next          = RESULT;
                operand_b_sel_next  = i_data_to_read;
                fifo_rx_read_next   = 1'b0;         // Stop reading
            end
        end

        RESULT: begin
            if (~i_fifo_tx_full) begin
                // If FIFO TX is not full, write the result
                state_next          = IDLE;         // Go back to IDLE after writing
                result_next         = i_alu_result; // Store ALU result
                fifo_tx_write_next  = 1'b1;         // Indicate that data is ready to write
            end
        end

        default: begin
            // Default state actions
            state_next          = IDLE;     // Fallback to IDLE state
            fifo_rx_read_next   = 1'b0;     // Ensure FIFO RX read is off
            fifo_tx_write_next  = 1'b0;     // Ensure FIFO TX write is off
        end
    endcase
end

// Assign output signals for interfacing
assign o_alu_op_A       = operand_a_sel;     // Output for ALU Operand A
assign o_alu_op_B       = operand_b_sel;     // Output for ALU Operand B
assign o_alu_opcode     = opcode_sel;        // Output for ALU Opcode
assign o_data_to_write  = result;            // Data to write to FIFO TX
assign o_fifo_tx_write  = fifo_tx_write;     // FIFO TX write control signal
assign o_fifo_rx_read   = fifo_rx_read;      // FIFO RX read control signal

endmodule
