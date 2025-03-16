`timescale 1ns / 1ps

module command_parser (
    input wire clk,                     // System clock
    input wire reset,                   // System reset

    // UART Interface
    input wire [7:0] uart_data,         // Data from UART
    input wire uart_data_valid,         // Valid signal from UART
    output reg parser_ready,             // Ready signal to indicate parser can accept new data

    // Framebuffer Interface
    output reg fb_write_enable,         // Write enable for framebuffer
    output reg [8:0] fb_write_x,        // X coordinate (0-319)
    output reg [7:0] fb_write_y,        // Y coordinate (0-199)
    output reg [7:0] fb_write_data,     // Pixel color value

    // Palette Interface
    output reg palette_write_enable,    // Write enable for palette
    output reg [7:0] palette_index,     // Palette index (0-255)
    output reg [3:0] palette_r,         // Red component
    output reg [3:0] palette_g,         // Green component
    output reg [3:0] palette_b          // Blue component
);

    // Command opcodes
    localparam CMD_SET_PIXEL = 8'h01;
    localparam CMD_SET_PALETTE = 8'h02;

    // State machine states
    typedef enum logic [3:0] {
        WAIT_CMD,           // Wait for command byte

        // SET_PIXEL states
        PIXEL_X_HIGH,       // Receive high byte of X
        PIXEL_X_LOW,        // Receive low byte of X
        PIXEL_Y_HIGH,       // Receive high byte of Y
        PIXEL_Y_LOW,        // Receive low byte of Y
        PIXEL_COLOR,        // Receive color value

        // SET_PALETTE states
        PALETTE_INDEX,      // Receive palette index
        PALETTE_R,          // Receive red value
        PALETTE_G,          // Receive green value
        PALETTE_B           // Receive blue value
    } parser_state_t;

    // Registers
    parser_state_t state = WAIT_CMD;
    reg [7:0] current_cmd = 0;
    reg [15:0] temp_x = 0;
    reg [15:0] temp_y = 0;

    always @(posedge clk) begin
        if (reset) begin
            state <= WAIT_CMD;
            current_cmd <= 0;
            temp_x <= 0;
            temp_y <= 0;

            // Outputs
            fb_write_enable <= 0;
            fb_write_x <= 0;
            fb_write_y <= 0;
            fb_write_data <= 0;

            palette_write_enable <= 0;
            palette_index <= 0;
            palette_r <= 0;
            palette_g <= 0;
            palette_b <= 0;

            parser_ready <= 1;
        end else begin
            // Default values for enables
            fb_write_enable <= 0;
            palette_write_enable <= 0;

            // Default value for parser_ready
            // The parser is ready to accept new data when in WAIT_CMD state
            parser_ready <= (state == WAIT_CMD);

            // Process UART data when valid
            if (uart_data_valid) begin
                case (state)
                    WAIT_CMD: begin
                        current_cmd <= uart_data;

                        case (uart_data)
                            CMD_SET_PIXEL: state <= PIXEL_X_HIGH;
                            CMD_SET_PALETTE: state <= PALETTE_INDEX;
                            default: state <= WAIT_CMD; // Invalid command, stay in wait
                        endcase
                    end

                    // SET_PIXEL states
                    PIXEL_X_HIGH: begin
                        temp_x[15:8] <= uart_data;
                        state <= PIXEL_X_LOW;
                    end

                    PIXEL_X_LOW: begin
                        temp_x[7:0] <= uart_data;
                        state <= PIXEL_Y_HIGH;
                    end

                    PIXEL_Y_HIGH: begin
                        temp_y[15:8] <= uart_data;
                        state <= PIXEL_Y_LOW;
                    end

                    PIXEL_Y_LOW: begin
                        temp_y[7:0] <= uart_data;
                        state <= PIXEL_COLOR;
                    end

                    PIXEL_COLOR: begin
                        // Validate coordinates before writing
                        if (temp_x < 320 && temp_y < 200) begin
                            fb_write_x <= temp_x[8:0];
                            fb_write_y <= temp_y[7:0];
                            fb_write_data <= uart_data;
                            fb_write_enable <= 1;
                        end

                        // Return to wait state
                        state <= WAIT_CMD;
                    end

                    // SET_PALETTE states
                    PALETTE_INDEX: begin
                        palette_index <= uart_data;
                        state <= PALETTE_R;
                    end

                    PALETTE_R: begin
                        // Scale from 8-bit to 4-bit (take upper 4 bits)
                        palette_r <= uart_data[7:4];
                        state <= PALETTE_G;
                    end

                    PALETTE_G: begin
                        // Scale from 8-bit to 4-bit (take upper 4 bits)
                        palette_g <= uart_data[7:4];
                        state <= PALETTE_B;
                    end

                    PALETTE_B: begin
                        // Scale from 8-bit to 4-bit (take upper 4 bits)
                        palette_b <= uart_data[7:4];
                        palette_write_enable <= 1;

                        // Return to wait state
                        state <= WAIT_CMD;
                    end

                    default: state <= WAIT_CMD;
                endcase
            end
        end
    end
    
endmodule