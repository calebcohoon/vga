`timescale 1ns / 1ps

module uart_receiver #(
    parameter CLK_FREQ = 25000000,  // Clock frequency in Hz
    parameter BAUD_RATE = 115200    // UART baud rate
)(
    input wire clk,                 // System clock
    input wire reset,               // System reset
    input wire rx,                  // UART RX signal
    output reg [7:0] rx_data,       // Received byte
    output reg rx_data_valid        // Data valid signal
);

    // Calculate clock cyles per bit
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    // State machine states
    typedef enum logic [2:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT,
        CLEANUP
    } uart_state_t;

    // Registers
    uart_state_t state = IDLE;
    reg [15:0] clock_count = 0;     // Counter for timing
    reg [2:0] bit_index = 0;        // Bit position counter (0-7)
    reg [7:0] rx_byte = 0;          // Temporary storage for receiving byte

    // Double-register the rx input to avoid metastability
    reg rx_sync1 = 1;
    reg rx_sync2 = 1;

    always @(posedge clk) begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end

    // UART RX logic
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            rx_data_valid <= 0;
            clock_count <= 0;
            bit_index <= 0;
        end else begin
            // Default state for rx_data_valid
            rx_data_valid <= 0;

            case (state)
                IDLE: begin
                    // Wait for start bit (low)
                    if (rx_sync2 == 0) begin
                        state <= START_BIT;
                        clock_count <= 0;
                    end
                end

                START_BIT: begin
                    // Sample in the middle of the start bit
                    if (clock_count == (CLKS_PER_BIT - 1) / 2) begin
                        // Verify it's still low
                        if (rx_sync2 == 0) begin
                            clock_count <= 0;
                            state <= DATA_BITS;
                            bit_index <= 0;
                        end else begin
                            // False start, return to idle
                            state <= IDLE;
                        end
                    end else begin
                        clock_count <= clock_count + 1;
                    end
                end

                DATA_BITS: begin
                    // Sample in the middle of each data bit
                    if (clock_count == CLKS_PER_BIT - 1) begin
                        clock_count <= 0;
                        rx_byte[bit_index] <= rx_sync2;

                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STOP_BIT;
                        end
                    end else begin
                        clock_count <= clock_count + 1;
                    end
                end

                STOP_BIT: begin
                    // Sample stop bit
                    if (clock_count == CLKS_PER_BIT - 1) begin
                        if (rx_sync2 == 1) begin
                            // Valid stop bit, output the data
                            rx_data <= rx_byte;
                            rx_data_valid <= 1;
                        end

                        clock_count <= 0;
                        state <= CLEANUP;
                    end else begin
                        clock_count <= clock_count + 1;
                    end
                end

                CLEANUP: begin
                    // Wait a bit before going back to idle
                    // This helps with systems that send bytes back-to-back
                    if (clock_count == CLKS_PER_BIT / 2) begin
                        state <= IDLE;
                        clock_count <= 0;
                    end else begin
                        clock_count <= clock_count + 1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
