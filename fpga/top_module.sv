`timescale 1ns / 1ps

module top_module (
    input wire clk_100mhz,      // 100 MHz system clock from Arty
    input wire reset_n,         // Active low reset from Arty button
    input wire uart_rx,         // UART RX from USB-UART bridge
    
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

    // UART signals
    wire [7:0] uart_data;
    wire uart_data_valid;

    // Instantiate the UART receiver
    uart_receiver uart_inst (
        .clk(clk_25mhz),
        .reset(reset),
        .rx(uart_rx),
        .rx_data(uart_data),
        .rx_data_valid(uart_data_valid)
    );

    // Command parser signals
    wire fb_write_enable;
    wire [8:0] fb_write_x;
    wire [7:0] fb_write_y;
    wire [7:0] fb_write_data;

    wire palette_write_enable;
    wire [7:0] palette_index;
    wire [3:0] palette_r;
    wire [3:0] palette_g;
    wire [3:0] palette_b;

    // Instantiate the command parser
    command_parser cmd_parser (
        .clk(clk_25mhz),
        .reset(reset),
        .uart_data(uart_data),
        .uart_data_valid(uart_data_valid),
        .fb_write_enable(fb_write_enable),
        .fb_write_x(fb_write_x),
        .fb_write_y(fb_write_y),
        .fb_write_data(fb_write_data),
        .palette_write_enable(palette_write_enable),
        .palette_index(palette_index),
        .palette_r(palette_r),
        .palette_g(palette_g),
        .palette_b(palette_b)
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
        .write_enable(fb_write_enable),
        .write_x(fb_write_x),
        .write_y(fb_write_y),
        .write_data(fb_write_data)
    );
    
    // Color palette signals
    wire [3:0] palette_r_out;
    wire [3:0] palette_g_out;
    wire [3:0] palette_b_out;

    // Instantiate the color palette
    color_palette palette_inst (
        .clk(clk_25mhz),
        .reset(reset),
        .color_index(pixel_color_index),
        .red(palette_r_out),
        .green(palette_g_out),
        .blue(palette_b_out),
        .write_enable(palette_write_enable),
        .write_index(palette_index),
        .write_r(palette_r),
        .write_g(palette_g),
        .write_b(palette_b)
    );
    
    // Connect color output
    assign vga_r = in_display_area ? palette_r_out : 4'h0;
    assign vga_g = in_display_area ? palette_g_out : 4'h0;
    assign vga_b = in_display_area ? palette_b_out : 4'h0;
    
    // Debug LEDs
    assign led[0] = clk_locked;
    assign led[1] = vga_hsync;
    assign led[2] = vga_vsync;
    assign led[3] = uart_data_valid;
    
endmodule
