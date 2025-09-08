// UART Transmitter Module
// This module handles the transmission of data over UART protocol.
// Parameters:
// - NB_DATA: Width of the data bus (number of bits in the data to transmit).
// - N_TICKS: Number of clock ticks for the STOP bit duration.

`timescale 1ns/1ps


module uart_tx #
(
    parameter NB_DATA = 8,  // Data width
    parameter N_TICKS = 16  // Number of ticks for STOP bit duration
)
(
    input wire i_clk,                    // Input clock signal
    input wire i_reset,                  // Asynchronous reset signal
    input wire i_tx_ready,               // Signal indicating that the transmitter is ready to send data
    input wire i_tick,                   // Clock tick signal for timing
    input wire [NB_DATA-1 : 0] i_din,    // Data input to be transmitted
    output reg o_tx_done,                // Signal indicating that transmission is complete
    output wire o_tx                     // Output data line for transmission
);

// State definitions for the UART transmitter
localparam [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

// State and data registers
reg [1:0] state, state_next;                    // Current and next state
reg [3:0] s, s_next;                            // Bit timing counter
reg [2:0] n, n_next;                            // Data bit index
reg [NB_DATA-1:0] send_byte, send_byte_next;    // Data to be sent
reg tx, tx_next;                                // Output data line state

// Synchronous process: Update state and registers on the rising edge of the clock
always @(posedge i_clk) begin
    if (i_reset) begin
        // Reset state and registers to initial values
        state <= IDLE;
        s <= 0;
        n <= 0;
        send_byte <= 0;
        tx <= 1'b1;                             // Idle state is high
    end
    else begin
        // Update state and registers with the next values
        state <= state_next;
        s <= s_next;
        n <= n_next;
        send_byte <= send_byte_next;
        tx <= tx_next;
    end
end

// Combinational process: Determine next state and output values based on current state
always @(*) begin
    // Default assignments
    state_next = state;
    o_tx_done = 1'b0;
    s_next = s;
    n_next = n;
    send_byte_next = send_byte;
    tx_next = tx;

    // State machine for UART transmission
    case (state)
        IDLE: begin
            tx_next = 1'b1;                             // Transmitter idle state is high
            if (i_tx_ready) begin
                // Transition to START state when ready to send data
                state_next      = START;
                s_next          = 0;                    // Reset bit timing counter
                send_byte_next  = i_din;                // Load data to send
            end
        end
        
        START: begin
            tx_next = 1'b0;                             // Start bit is low
            if (i_tick) begin
                if (s == 15) begin
                    // Transition to DATA state after start bit duration
                    state_next  = DATA;
                    s_next      = 0;                    // Reset bit timing counter
                    n_next      = 0;                    // Reset data bit index
                end
                else begin
                    s_next      = s + 1;                // Increment bit timing counter
                end
            end
        end

        DATA: begin
            // Send current data bit
            tx_next = send_byte[0];
            if (i_tick) begin
                if (s == 15) begin
                    // Transition to next data bit after duration
                    s_next          = 0;                // Reset bit timing counter
                    send_byte_next  = send_byte >> 1;   // Shift out the next bit
                    if (n == (NB_DATA - 1)) begin
                        // If all data bits are sent, transition to STOP state
                        state_next  = STOP;
                    end
                    else begin
                        n_next      = n + 1;            // Increment data bit index
                    end
                end
                else begin
                    s_next = s + 1;                     // Increment bit timing counter
                end
            end
        end

        STOP: begin
            tx_next = 1'b1;                 // Stop bit is high
            if (i_tick) begin
                if (s == (N_TICKS - 1)) begin
                    // Transition back to IDLE state after stop bit duration
                    state_next  = IDLE;
                    o_tx_done   = 1'b1;     // Indicate transmission is complete
                end
                else begin
                    s_next      = s + 1;    // Increment bit timing counter
                end
            end
        end
        
        default: begin
            state_next = IDLE;              // Default state is IDLE
        end
    endcase
end

// Assign output for the transmitted data line
assign o_tx = tx;

endmodule
