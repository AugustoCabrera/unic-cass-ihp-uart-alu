`timescale 1ns / 1ps

// UART Receiver Module
// This module handles the reception of data over UART protocol.
// Parameters:
// - NB_DATA: Width of the data bus (number of bits in the data received).
// - N_TICKS: Number of clock ticks for the STOP bit duration.

module uart_rx #(
    parameter NB_DATA = 8,  // Data width
    parameter N_TICKS = 16  // Number of ticks for STOP bit duration
)
(
    input wire i_clk,                     // Input clock signal
    input wire i_reset,                   // Asynchronous reset signal
    input wire i_rx,                      // Received data line
    input wire i_tick,                    // Clock tick signal for timing
    output reg o_rx_done,                 // Signal indicating that reception is complete
    output wire [NB_DATA-1:0] o_dout      // Output data from reception
);

// State definitions for the UART receiver
localparam [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

// State and data registers
reg [1:0] state, state_next;                // Current and next state
reg [3:0] s, s_next;                        // Bit timing counter
reg [2:0] n, n_next;                        // Data bit index
reg [NB_DATA-1:0] received_byte, received_byte_next; // Received data byte

// Synchronous process: Update state and registers on the rising edge of the clock
always @(posedge i_clk) begin
    if (i_reset) begin
        // Reset state and registers to initial values
        state           <= IDLE;
        s               <= 0;
        n               <= 0;
        received_byte   <= 0;
    end
    else begin
        // Update state and registers with the next values
        state           <= state_next;
        s               <= s_next;
        n               <= n_next;
        received_byte   <= received_byte_next;
    end
end

// Combinational process: Determine next state and output values based on current state
always @(*) begin
    // Default assignments
    state_next          = state;
    o_rx_done           = 1'b0; // Default to not done
    s_next              = s;
    n_next              = n;
    received_byte_next  = received_byte;

    // State machine for UART reception
    case (state)
        IDLE: begin
            if (~i_rx) begin
                // Transition to START state when the start bit (low) is detected
                state_next  = START;
                s_next      = 0; // Reset bit timing counter
            end
        end
        
        START: begin
            if (i_tick) begin
                if (s == 7) begin
                    // Transition to DATA state after detecting start bit duration
                    state_next  = DATA;
                    s_next      = 0; // Reset bit timing counter
                    n_next      = 0; // Reset data bit index
                end
                else begin
                    s_next      = s + 1; // Increment bit timing counter
                end
            end
        end

        DATA: begin
            if (i_tick) begin
                if (s == 15) begin
                    // Read current data bit into received_byte
                    s_next = 0; // Reset bit timing counter
                    received_byte_next = {i_rx, received_byte[NB_DATA-1:1]}; // Shift in new bit
                    if (n == (NB_DATA - 1)) begin
                        // If all data bits have been received, transition to STOP state
                        state_next = STOP;
                    end
                    else begin
                        n_next = n + 1; // Increment data bit index
                    end
                end
                else begin
                    s_next = s + 1; // Increment bit timing counter
                end
            end
        end

        STOP: begin
            if (i_tick) begin
                if (s == (N_TICKS - 1)) begin
                    // Transition back to IDLE state after receiving the stop bit
                    state_next = IDLE;
                    if (i_rx) begin
                        o_rx_done = 1'b1; // Indicate that reception is complete if stop bit is valid
                    end
                end
                else begin
                    s_next = s + 1; // Increment bit timing counter
                end
            end
        end

        default: begin
            state_next = IDLE; // Default state is IDLE
        end
    endcase
end

// Assign output for the received data
assign o_dout = received_byte;

endmodule
