`timescale 1ns / 1ps

module top_module(
    input wire clk_100mhz,      // 100 MHz system clock from Arty
    input wire reset_n,         // Active low reset from Arty button
    
    // VGA PMOD connections
    output wire vga_hsync,      // Horizontal sync
    output wire vga_vsync,      // Vertical sync
    output wire [3:0] vga_r,    // Red channel
    output wire [3:0] vga_g,    // Green channel
    output wire [3:0] vga_b     // Blue channel
);

    // Generate 25 MHz clock using the MMCM (Mixed-Mode Clock Manager)
    wire clk_25mhz;
    wire clk_locked;
    
    // Instantiate clock generator
    clock_generator clk_gen (
        .clk_in(clk_100mhz),
        .clk_out(clk_25mhz),
        .reset(~reset_n),
        .locked(clk_locked)
    );

    // Reset when the button is pressed or when the clock is not locked
    wire reset = ~reset_n | ~clk_locked;
    
    // VGA controller signals
    wire [9:0] h_count;
    wire [9:0] v_count;
    wire display_enable;
    
    // Instantiate the VGA controller
    vga_controller vga_inst (
        .clk_25mhz(clk_25mhz),
        .reset(reset),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .h_count(h_count),
        .v_count(v_count),
        .display_enable(display_enable)
    );
    
    // Simple test pattern for initial testing
    // Generate color bars
    wire [1:0] pattern_h = h_count[8:7];
    wire [1:0] pattern_v = v_count[8:7];
    
    // Color generation based on pattern
    assign vga_r = display_enable ? (pattern_h == 2'd0 || pattern_h == 2'd3 ? 4'hF : 4'h0) : 4'h0;
    assign vga_g = display_enable ? (pattern_h == 2'd1 || pattern_h == 2'd3 ? 4'hF : 4'h0) : 4'h0;
    assign vga_b = display_enable ? (pattern_h == 2'd2 || pattern_h == 2'd3 ? 4'hF : 4'h0) : 4'h0;
endmodule
