`timescale 1ns / 1ps

module clock_generator (
    input wire clk_in,      // Input clock (100 MHz)
    input wire reset,       // Active high reset
    output wire clk_out,    // Output clock (25 MHz)
    output wire locked      // PLL locked signal
);

    // Internal signals
    wire clk_fb;        // Feedback clock
    wire clk_out_pll;   // PLL output clock
    
    // MMCM instance
    // 100 MHz -> 25 MHz for VGA signal
    // For Artix7 use MMCME2_BASE
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),    // Jitter programming
        .CLKFBOUT_MULT_F(10.0),     // Multiply input clock by 10 to get 1000 MHz
        .CLKFBOUT_PHASE(0.0),       // No phase shift
        .CLKIN1_PERIOD(10.0),       // 10ns for 100 MHz input clock
        
        // Output clock divide values
        .CLKOUT0_DIVIDE_F(40.0),    // Divide by 40 to get 25 MHz
        .CLKOUT0_DUTY_CYCLE(0.5),   // 50% duty cycle
        .CLKOUT0_PHASE(0.0),        // No phase shift
        
        .DIVCLK_DIVIDE(1),          // Don't divide input clock
        .REF_JITTER1(0.01),         // Expected input jitter
        .STARTUP_WAIT("FALSE")      // Don't wait for PLL lock
    )
    mmcm_inst (
        // Clock outputs
        .CLKOUT0(clk_out_pll),      // 25 MHz output
        .CLKOUT0B(),                // Unused
        .CLKOUT1(),                 // Unused
        .CLKOUT1B(),                // Unused
        .CLKOUT2(),                 // Unused
        .CLKOUT2B(),                // Unused
        .CLKOUT3(),                 // Unused
        .CLKOUT3B(),                // Unused
        .CLKOUT4(),                 // Unused
        .CLKOUT5(),                 // Unused
        .CLKOUT6(),                 // Unused
        
        // Control ports
        .LOCKED(locked),            // PLL lock signal
        
        // Control inputs
        .CLKIN1(clk_in),            // 100 MHz input
        .CLKFBIN(clk_fb),           // Feedback input
        
        // Clock feedback output
        .CLKFBOUT(clk_fb),          // Feedback output
        
        // Power control
        .PWRDWN(1'b0),              // Not powered down
        .RST(reset)                 // Reset input
    );
    
    // Buffer the clock output
    BUFG clkout_buf (
        .I(clk_out_pll),
        .O(clk_out)
    );
endmodule
