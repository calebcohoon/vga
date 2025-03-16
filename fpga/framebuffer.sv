`timescale 1ns / 1ps

module framebuffer (
    input wire clk,                 // Clock
    input wire reset,               // Reset

    // Read port for VGA output
    input wire [8:0] read_x,        // X coordinate
    input wire [7:0] read_y,        // Y coordinate
    output reg [7:0] pixel_data,    // 8-bit pixel value

    // Write port for pixel updates
    input wire write_enable,
    input wire [8:0] write_x,       // X coordinate
    input wire [7:0] write_y,       // Y coordinate
    input wire [7:0] write_data     // 8-bit pixel value
);

    // Parameters for framebuffer dimensions
    parameter FB_WIDTH = 320;
    parameter FB_HEIGHT = 200;
    parameter FB_DEPTH = 8;

    // Memory to store the pixels
    reg [FB_DEPTH-1:0] buffer[0:FB_WIDTH * FB_HEIGHT-1];

    // Address calculation
    wire [16:0] read_addr = read_y * FB_WIDTH + read_x;
    wire [16:0] write_addr = write_y * FB_WIDTH + write_x;

    // Write port logic
    always @(posedge clk) begin
        pixel_data <= buffer[read_addr];

        if (write_enable) begin
            buffer[write_addr] <= write_data;
        end
    end

endmodule
