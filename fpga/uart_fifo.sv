`timescale 1ns / 1ps

module uart_fifo #(
    parameter DEPTH = 16,   // Size of the FIFO
    parameter WIDTH = 8     // Width of the data
)(
    input wire clk,
    input wire reset,

    // Input interface (from UART receiver)
    input wire [WIDTH-1:0] data_in,
    input wire write_en,
    output wire full,

    // Output interface (to command parser)
    output reg [WIDTH-1:0] data_out,
    input wire read_en,
    output wire empty
);

    // FIFO memory
    reg [WIDTH-1:0] buffer [0:DEPTH-1];

    // Pointers
    reg [$clog2(DEPTH):0] write_ptr = 0;
    reg [$clog2(DEPTH):0] read_ptr = 0;

    // Status flags
    wire [$clog2(DEPTH):0] count = write_ptr - read_ptr;
    assign empty = (count == 0);
    assign full = (count >= DEPTH);

    // Write to FIFO
    always @(posedge clk) begin
        if (reset) begin
            write_ptr <= 0;
        end else if (write_en && !full) begin
            buffer[write_ptr[$clog2(DEPTH)-1:0]] <= data_in;
            write_ptr <= write_ptr + 1;
        end
    end

    // Read from FIFO
    always @(posedge clk) begin
        if (reset) begin
            read_ptr <= 0;
            data_out <= 0;
        end else if (read_en && !empty) begin
            data_out <= buffer[read_ptr[$clog2(DEPTH)-1:0]];
            read_ptr <= read_ptr + 1;
        end
    end

endmodule