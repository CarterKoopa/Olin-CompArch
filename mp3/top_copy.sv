//
// Mini-Project 3 - Game of Life
// Olin Computer Architecture FA25
//
// Top-level test module for WS2812B LED matrix
// Cycles through all 64 LEDs in Red, Blue, Green order over 15 seconds
//
// Author: Carter Harris
`include "led_control.sv"

module top(
    input logic clk,
    output logic _48b,  // Matrix data output
    output logic _45a
);
    logic next_led;
    logic matrix_output;
    logic send_reset = 1'b0;
    logic [23:0] current_led_value = 0;
    logic on_code_signal;

    led_control #(
        // Parameters
    ) u1 (
        .clk            (clk),
        .rgb_input      (current_led_value),
        .resetting      (send_reset),
        .next_led       (next_led),
        .led_signal     (matrix_output),
        .on_code_signal (on_code_signal)
    );

    assign _48b = clk;
    assign _45a = on_code_signal;

endmodule