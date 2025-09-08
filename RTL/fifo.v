// FIFO (First-In-First-Out) Buffer Module
// Parameters:
// - NB_DATA: Width of the data bus (size of each data element).
// - PTR_LEN: Width of the read and write pointers (defines the depth of the FIFO buffer).

`timescale 1ns/1ps


module fifo #
(
    parameter NB_DATA = 8,                      // Data width
    parameter PTR_LEN = 4                       // Pointer width (FIFO depth is 2^PTR_LEN)
)
(
    input wire i_clk,                           // Input clock signal
    input wire i_reset,                         // Asynchronous reset signal
    input wire i_read_fifo,                     // Read enable signal
    input wire i_write_fifo,                    // Write enable signal
    input wire [NB_DATA-1 : 0] i_data_to_write, // Data to write into FIFO
    output wire o_fifo_is_empty,                // FIFO empty flag
    output wire o_fifo_is_full,                 // FIFO full flag
    output wire [NB_DATA-1 : 0] o_data_to_read  // Data read from FIFO
);

// Local parameters for operation modes
localparam READ         = 2'b01;
localparam WRITE        = 2'b10;
localparam READWRITE    = 2'b11;

// FIFO memory array (2^PTR_LEN deep, NB_DATA bits wide)
reg [NB_DATA-1 : 0] array [(2**PTR_LEN)-1 : 0];

// Read and write pointers (current and next values)
reg [PTR_LEN-1 : 0] write_ptr, write_ptr_next, write_ptr_ok;
reg [PTR_LEN-1 : 0] read_ptr, read_ptr_next, read_ptr_ok;

// Full and empty status flags (current and next values)
reg full, full_next;
reg empty, empty_next;

// Write enable signal (determines whether to write data to FIFO)
wire write_enable;

// Memory write operation (write to FIFO at the position indicated by write_ptr)
always @(posedge i_clk) begin
    if (write_enable) begin
        array[write_ptr] <= i_data_to_write;
    end
end

// Read operation (read from FIFO at the position indicated by read_ptr)
assign o_data_to_read = array[read_ptr];

// Write enable is high only if write operation is requested and FIFO is not full
assign write_enable = i_write_fifo & ~full;

// Sequential block: Update pointers and status flags on the rising edge of the clock
always @(posedge i_clk) begin
    if (i_reset) begin
        // Reset FIFO pointers and status flags
        write_ptr   <= 0;
        read_ptr    <= 0;
        full        <= 0;
        empty       <= 1;
    end
    else begin
        // Update pointers and status flags with the next values
        write_ptr   <= write_ptr_next;
        read_ptr    <= read_ptr_next;
        full        <= full_next;
        empty       <= empty_next;
    end
end

// Combinational block: Compute the next values for the pointers and status flags
always @(*) begin
    // Calculate the next positions for the write and read pointers
    write_ptr_ok    = write_ptr + 1;
    read_ptr_ok     = read_ptr + 1;

    // Default: retain current pointer and flag values
    write_ptr_next  = write_ptr;
    read_ptr_next   = read_ptr;
    full_next       = full;
    empty_next      = empty;

    // Handle read, write, and simultaneous read/write operations
    case ({i_write_fifo, i_read_fifo})
        READ:  // Read operation
            if (~empty) begin
                read_ptr_next = read_ptr_ok;    // Increment the read pointer
                full_next = 1'b0;               // Clear the full flag
                if (read_ptr_ok == write_ptr) begin
                    empty_next = 1'b1;          // Set empty flag if read pointer catches up to write pointer
                end
            end
        WRITE:  // Write operation
            if (~full) begin
                write_ptr_next  = write_ptr_ok;         // Increment the write pointer
                empty_next      = 1'b0;                 // Clear the empty flag
                if (write_ptr_ok == read_ptr) begin
                    full_next = 1'b1;                   // Set full flag if write pointer catches up to read pointer
                end
            end
        READWRITE:  // Simultaneous read and write operation
            begin
                write_ptr_next  = write_ptr_ok;  // Increment both pointers
                read_ptr_next   = read_ptr_ok;
            end
        default:  // No operation
            begin
                // Maintain the current pointer values (no changes)
                write_ptr_next  = write_ptr_next;
                read_ptr_next   = read_ptr_next;
            end
    endcase
end

// Assign output flags
assign o_fifo_is_full   = full;
assign o_fifo_is_empty  = empty;

endmodule
