`timescale 1ns / 1ps

module vga_controller (
    input wire clk_25mhz,       // 25 MHz clock
    input wire reset,           // Active high reset
    output wire hsync,          // Horizontal sync
    output wire vsync,          // Vertical sync
    output wire [9:0] h_count,  // Horizontal counter
    output wire [9:0] v_count,  // Vertical counter
    output wire display_enable  // High when in display area    
);

    // VGA 640x480 @ 60Hz timing parameters
    // Horizontal timing in pixels
    parameter H_DISPLAY = 640;      // Horizontal display width
    parameter H_FRONT   = 16;       // Front porch
    parameter H_SYNC    = 96;       // Sync pulse
    parameter H_BACK    = 48;       // Back porch
    parameter H_TOTAL   = H_DISPLAY + H_FRONT + H_SYNC + H_BACK; // Total cycle
    
    // Vertical timing in pixels
    parameter V_DISPLAY = 480;      // Vertical display height
    parameter V_FRONT   = 10;       // Front porch
    parameter V_SYNC    = 2;        // Sync pulse
    parameter V_BACK    = 33;       // Back porch
    parameter V_TOTAL   = V_DISPLAY + V_FRONT + V_SYNC + V_BACK; // Total cycle
    
    // Mode 13h logical display area (320x200 doubled to 640x480)
    parameter DISPLAY_WIDTH = 320;
    parameter DISPLAY_HEIGHT = 200;
    
    // Counters for horizontal and vertical sync
    reg [9:0] h_counter = 0;
    reg [9:0] v_counter = 0;
    
    // Assign outputs
    assign h_count = h_counter;
    assign v_count = v_counter;
    
    // Generate sync signals (active low for VGA)
    assign hsync = ~((h_counter >= (H_DISPLAY + H_FRONT)) && (h_counter < (H_DISPLAY + H_FRONT + H_SYNC)));
    assign vsync = ~((v_counter >= (V_DISPLAY + V_FRONT)) && (v_counter < (V_DISPLAY + V_FRONT + V_SYNC)));
    
    // Display enable logic
    // Only enable within the visible area and when our content should be displayed
    // Center the 640x400 image in the 640x480 frame
    wire h_in_display = (h_counter < H_DISPLAY);
    wire v_in_display = (v_counter < V_DISPLAY);
    wire v_in_logical = (v_counter >= ((V_DISPLAY - (DISPLAY_HEIGHT * 2)) / 2)) &&
                        (v_counter < ((V_DISPLAY - (DISPLAY_HEIGHT * 2)) / 2) + (DISPLAY_HEIGHT * 2));
                        
    assign display_enable = h_in_display && v_in_display && v_in_logical;
    
    // Horizontal counter
    always @(posedge clk_25mhz or posedge reset) begin
        if (reset) begin
            h_counter <= 0;
        end else begin
            if (h_counter < H_TOTAL - 1) begin
                h_counter <= h_counter + 1;
            end else begin
                h_counter <= 0;
            end
        end
    end
    
    // Vertical counter
    always @(posedge clk_25mhz or posedge reset) begin
        if (reset) begin
            v_counter <= 0;
        end else begin
            if (h_counter == H_TOTAL - 1) begin
                if (v_counter < V_TOTAL - 1) begin
                    v_counter <= v_counter + 1;
                end else begin
                    v_counter <= 0;
                end
            end
        end
    end

endmodule
