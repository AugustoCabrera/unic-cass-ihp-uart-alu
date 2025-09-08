`timescale 1ns/1ps


module uart_interface#
(
    parameter NB_DATA = 8,
    parameter N_TICKS = 16,
    parameter COUNTER_LIMIT = 326,
    parameter NB_COUNTER = 9,
    parameter PTR_LEN = 2        
)
(
    input wire i_clk,
    input wire i_reset,
    input wire i_read_uart,
    input wire i_write_uart,
    input wire i_rx,
    input wire [NB_DATA-1 : 0] i_data_to_write,
    output wire o_tx_full,
    output wire o_rx_empty,
    output wire o_tx,
    output wire [NB_DATA-1 : 0] o_data_to_read
);


wire tick;
wire tx_done;
wire tx_empty;
wire tx_not_empty;
wire rx_done;
wire [NB_DATA-1 : 0] tx_fifo_out;
wire [NB_DATA-1 : 0] rx_data_out;

/* verilator lint_off UNUSED */
wire rx_fifo_full_unused;
/* verilator lint_on UNUSED */


baud_rate#
(
    .COUNTER_LIMIT(COUNTER_LIMIT),
    .NB_COUNTER(NB_COUNTER)
) baud_rateUnit
(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .o_tick(tick)
);

uart_rx #
(
    .NB_DATA(NB_DATA),
    .N_TICKS(N_TICKS)
) uartRxUnit
(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_rx(i_rx),
    .i_tick(tick),
    .o_rx_done(rx_done),
    .o_dout(rx_data_out)
);

fifo #
(
    .NB_DATA(NB_DATA),
    .PTR_LEN(PTR_LEN)
) fifoRX
(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_read_fifo(i_read_uart),
    .i_write_fifo(rx_done),
    .i_data_to_write(rx_data_out),
    .o_fifo_is_empty(o_rx_empty),
    .o_fifo_is_full(rx_fifo_full_unused), //  dummy
    .o_data_to_read(o_data_to_read)
);

fifo #
(
    .NB_DATA(NB_DATA),
    .PTR_LEN(PTR_LEN)
) fifoTX
(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_read_fifo(tx_done),
    .i_write_fifo(i_write_uart),
    .i_data_to_write(i_data_to_write),
    .o_fifo_is_empty(tx_empty),
    .o_fifo_is_full(o_tx_full),
    .o_data_to_read(tx_fifo_out)
);

uart_tx #
(
    .NB_DATA(NB_DATA),
    .N_TICKS(N_TICKS)
) uartTxUnit
(
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_tx_ready(tx_not_empty),
    .i_tick(tick),
    .i_din(tx_fifo_out),
    .o_tx_done(tx_done),
    .o_tx(o_tx)
);

assign tx_not_empty = ~tx_empty;

endmodule
