`timescale 1ns / 1ps

module top_module (
    input wire clk_100mhz,      // 100 MHz system clock from Arty
    input wire reset_n,         // Active low reset from Arty button
    
    // VGA PMOD connections
    output wire vga_hsync,      // Horizontal sync
    output wire vga_vsync,      // Vertical sync
    output wire [3:0] vga_r,    // Red channel
    output wire [3:0] vga_g,    // Green channel
    output wire [3:0] vga_b,    // Blue channel
    
    // Debug outputs
    output wire [3:0] led       // Onboard LEDs for debug
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
    
    // Pixel doubling signals
    wire [8:0] logical_x;   // 0-319
    wire [7:0] logical_y;   // 0-199
    wire in_display_area;
    
    // Instantiate the pixel mapping module
    pixel_mapping pm_inst (
        .h_count(h_count),
        .v_count(v_count),
        .display_enable(display_enable),
        .logical_x(logical_x),
        .logical_y(logical_y),
        .in_display_area(in_display_area)
    );

    // Framebuffer signals
    wire [7:0] pixel_color_index;

    // Instantiate the framebuffer
    framebuffer fb_inst (
        .clk(clk_25mhz),
        .reset(reset),
        .read_x(logical_x),
        .read_y(logical_y),
        .pixel_data(pixel_color_index),
        .write_enable(1'b0),    // Hardwired to 0 for now
        .write_x(9'd0),         // Not used yet
        .write_y(8'd0),         // Not used yet
        .write_data(8'd0)       // Not used yet
    );
    
    // Color palette signals
    wire [3:0] palette_r;
    wire [3:0] palette_g;
    wire [3:0] palette_b;

    // Instantiate the color palette
    color_palette palette_inst (
        .clk(clk_25mhz),
        .reset(reset),
        .color_index(pixel_color_index),
        .red(palette_r),
        .green(palette_g),
        .blue(palette_b),
        .write_enable(1'b0),    // Hardwired to 0 for now
        .write_index(8'd0),     // Not used yet
        .write_r(4'd0),         // Not used yet
        .write_g(4'd0),         // Not used yet
        .write_b(4'd0)          // Not used yet
    );
    
    // Connect color output
    assign vga_r = in_display_area ? palette_r : 4'h0;
    assign vga_g = in_display_area ? palette_g : 4'h0;
    assign vga_b = in_display_area ? palette_b : 4'h0;
    
    // Debug LEDs
    assign led[0] = clk_locked;
    assign led[1] = vga_hsync;
    assign led[2] = vga_vsync;
    assign led[3] = in_display_area;
    
endmodule
