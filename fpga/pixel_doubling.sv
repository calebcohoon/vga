`timescale 1ns / 1ps

module pixel_doubling(
    input wire clk_25mhz,
    input wire reset,
    input wire [9:0] h_count,       // Physical horizontal counter
    input wire [9:0] v_count,       // Physical vertical counter
    input wire display_enable,      // Display enable from VGA controller
    output wire [8:0] logical_x,    // Logical x coordinate
    output wire [7:0] logical_y,    // Logical y coordinate
    output wire in_display_area     // True when in 320x200 logical display area
);

    // Mode 13h logical display area parameters
    parameter LOGICAL_WIDTH = 320;
    parameter LOGICAL_HEIGHT = 200;
    parameter PHYSICAL_WIDTH = 640;
    parameter PHYSICAL_HEIGHT = 480;
    
    // Calculate vertical centering offset
    parameter V_OFFSET = (PHYSICAL_HEIGHT - (LOGICAL_HEIGHT * 2)) / 2;
    parameter H_OFFSET = 80; // (640 - (320 x 2)) / 2
    
    // Determine if the current pixel is in the display area
    wire h_active = (h_count >= H_OFFSET) && (h_count < (H_OFFSET + (LOGICAL_WIDTH * 2)));
    wire v_active = (v_count >= V_OFFSET) && (v_count < (V_OFFSET + (LOGICAL_HEIGHT * 2)));
    
    assign in_display_area = display_enable && h_active && v_active;
    
    // Convert physical coordinates to logical coordinates using pixel doubling
    assign logical_x = (h_count - H_OFFSET) >> 1; // (h_vount - H_OFFSET) / 2
    assign logical_y = (v_count - V_OFFSET) >> 1; // (v_vount - V_OFFSET) / 2
endmodule
