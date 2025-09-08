// Baud Rate Generator Module
// This module generates a baud rate clock tick based on a counter.
// Parameters:
// - NB_COUNTER: Number of bits in the counter (controls the maximum value the counter can hold).
// - COUNTER_LIMIT: Defines when the counter should reset (controls the baud rate).

`timescale 1ns/1ps


module baud_rate #
(
    parameter NB_COUNTER = 9,        // Width of the counter (in bits)
    parameter COUNTER_LIMIT = 326     // Limit for the counter (baud rate frequency divisor)
)
(
    input wire i_clk,
    input wire i_reset,
    output wire o_tick
);

// Internal counter register (holds the current count value)
reg [NB_COUNTER-1 : 0] counter;
// Next counter value (calculated each clock cycle)
wire [NB_COUNTER-1 : 0] counter_next;

// Synchronous process: Update the counter on every rising edge of i_clk
always @(posedge i_clk) begin
    if (i_reset) begin
        // If reset is active, reset the counter to 0
        counter <= 0;
    end
    else begin
        // Otherwise, update counter with the next calculated value
        counter <= counter_next;
    end
end

// Calculate the next value of the counter
// If counter reaches the COUNTER_LIMIT, reset to 0; otherwise, increment
assign counter_next = (counter == (COUNTER_LIMIT-1)) ? 0 : counter + 1;
assign o_tick = (counter == (COUNTER_LIMIT-1)) ? 1'b1 : 1'b0;

endmodule
