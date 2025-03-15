# Mode 13h-Style FPGA Graphics Card: Development Guide

## Project Overview
Creating a minimalist Mode 13h-inspired graphics system using an Arty A7 FPGA with VGA PMOD, providing a simple linear framebuffer interface via USB.

## Version 1 Specifications
- Resolution: 320×200 pixels (classic Mode 13h resolution)
- Display Method: Pixel doubling to 640×400 centered in 640×480 VGA
- Color depth: 8-bit indexed color (256 colors from palette)
- Interface: USB-UART for basic pixel data transfer
- Output: VGA via PMOD at 25 MHz pixel clock
- Memory: Linear framebuffer in FPGA block RAM

## Development Checklist

### Phase 1: VGA Controller with Pixel Doubling
- [X] Set up Vivado project for Arty A7
- [X] Configure 25 MHz clock for entire design
- [X] Implement VGA timing controller for 640×480@60Hz
  - [X] Generate horizontal sync (hsync) signal
  - [X] Generate vertical sync (vsync) signal
  - [X] Create horizontal and vertical counters
- [ ] Implement pixel doubling logic:
  - [ ] Map each logical 320×200 pixel to 2×2 physical pixels
  - [ ] Center the 640×400 image in the 640×480 frame
- [X] Connect VGA PMOD pins correctly
- [X] Test VGA output with static test pattern

### Phase 2: Framebuffer Implementation
- [ ] Design block RAM-based framebuffer (64KB for 320×200×8-bit)
- [ ] Implement address translation from VGA counters to framebuffer coordinates
  - [ ] h_addr = h_count >> 1 (divide by 2)
  - [ ] v_addr = v_count >> 1 (divide by 2)
  - [ ] fb_addr = (v_addr * 320) + h_addr
- [ ] Implement 256-entry color palette (3x8-bit RGB values)
- [ ] Set up default VGA-compatible palette
- [ ] Connect framebuffer output through palette to VGA RGB signals
- [ ] Test framebuffer with static test pattern

### Phase 3: USB-UART Communication
- [ ] Set up USB-UART interface using Arty's built-in bridge
  - [ ] Configure for 115200 baud
  - [ ] Implement simple command receiver
- [ ] Implement two basic commands:
  - [ ] Set pixel: `SET_PIXEL [X] [Y] [COLOR]`
  - [ ] Set palette entry: `SET_PALETTE [INDEX] [R] [G] [B]`
- [ ] Test basic pixel drawing via USB

### Phase 4: Simple PC Software
- [ ] Create minimal C/C++ program for PC side
- [ ] Implement serial port communication
- [ ] Create basic drawing functions:
  - [ ] `void init_graphics()`
  - [ ] `void set_pixel(int x, int y, uint8_t color)`
  - [ ] `void set_palette(int index, uint8_t r, uint8_t g, uint8_t b)`
- [ ] Create simple demo pattern to verify functionality

## Command Protocol Specification

### Basic Format
All commands use a simple byte format with a command ID followed by parameters.

### Command Set
1. **Set Pixel (0x01)**
   - Format: `[0x01][2B X][2B Y][1B COLOR]`
   - Total: 6 bytes
   - X range: 0-319, Y range: 0-199

2. **Set Palette Entry (0x02)**
   - Format: `[0x02][1B INDEX][1B R][1B G][1B B]`
   - Total: 5 bytes
   - Index range: 0-255, RGB range: 0-255 each

## Hardware Requirements
- Arty A7 FPGA board
- VGA PMOD
- USB cable for programming and communication
- VGA monitor

## Software Requirements
- Xilinx Vivado
- C/C++ compiler for PC software
