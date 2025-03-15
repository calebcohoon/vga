`timescale 1ns / 1ps

module color_palette (
    input wire clk,                 // Clock
    input wire reset,               // Reset

    // Read port
    input wire [7:0] color_index,   // 8-bit color index
    output wire [3:0] red,          // 4-bit red component
    output wire [3:0] green,        // 4-bit green component
    output wire [3:0] blue,         // 4-bit blue component

    // Write port for palette updates
    input wire write_enable,
    input wire [7:0] write_index,   // Palette entry to update
    input wire [3:0] write_r,       // New red value
    input wire [3:0] write_g,       // New green value
    input wire [3:0] write_b       // New blue value
);

    // 256-entry color palette, 12 bits per entry
    reg [11:0] palette [0:255];

    // Read port logic
    assign red = palette[color_index][11:8];
    assign green = palette[color_index][7:4];
    assign blue = palette[color_index][3:0];

    // Write port logic
    always @(posedge clk) begin
        if (write_enable) begin
            palette[write_index] <= {write_r, write_g, write_b};
        end
    end

    // Initialize with VGA palette
    integer i;
    initial begin
        // First 16 colors (CGA palette)
        palette[0] = 12'h000;   // Black
        palette[1] = 12'h00A;   // Blue
        palette[2] = 12'h0A0;   // Green
        palette[3] = 12'h0AA;   // Cyan
        palette[4] = 12'hA00;   // Red
        palette[5] = 12'hA0A;   // Magenta
        palette[6] = 12'hA50;   // Brown
        palette[7] = 12'hAAA;   // Light Gray
        palette[8] = 12'h555;   // Dark Gray
        palette[9] = 12'h55F;   // Light Blue
        palette[10] = 12'h5F5;   // Light Green
        palette[11] = 12'h5FF;   // Light Cyan
        palette[12] = 12'hF55;   // Light Red
        palette[13] = 12'hF5F;   // Light Magenta
        palette[14] = 12'hFF5;   // Yellow
        palette[15] = 12'hFFF;   // White

        // Rest of the palette
        for (i = 16; i < 256; i = i + 1) begin
            palette[i] = {
                4'(i & 12'h3),
                4'((i >> 2) & 12'h7),
                4'((i >> 5) & 12'h3)
            };
        end
    end

endmodule
