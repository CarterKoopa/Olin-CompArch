//
// Mini-Project 3 - Game of Life
// Olin Computer Architecture FA25
//
// Control an LED matrix of a given sized based around WS2812B 
//
// Author: Carter Harris
`include "led_control.sv"

module matrix_control #(
    parameter NUM_LEDS = 64,
    parameter TICKS_TO_RESET = 700 // 50us plus some buffer given its >=
)
(
    input logic clk,
    input logic [NUM_LEDS-1:0][23:0] led_data,
    input logic update_matrix,
    output logic matrix_output
);

    // Define the logic variables
    //
    // Track the 24-bit RGB signal for the current LED in the matrix
    logic [23:0] current_led_value;
    // Switch to reset the output at the end of the matrix
    logic send_reset;
    // Signal from the LED controller counter on when to send the next signal
    logic next_led;
    // Create a register to store a snapshot of the led_data so that it's not
    // updated during transmission.
    logic [NUM_LEDS-1:0][23:0] led_data_snapshot = 0;

    // Implement the underlying WS2812B LED Controller
    led_control #(
        // Parameters
    ) u1 (
        .clk            (clk),
        .rgb_input      (current_led_value),
        .resetting      (send_reset),
        .next_led       (next_led),
        .led_signal     (matrix_output)
    );

    // Define counter variables
    logic [$clog2(NUM_LEDS) - 1:0] current_led = 0;


    // Define state machine states
    typedef enum {TRANSMITTING, RESETTING, IDLE} matrix_state;
    matrix_state state;

    // This sequential block waits for the signal from the led_control to
    // increment to the next LED in the matrix. This should only occur at the
    // falling edge of next_led, which means the last bit from the LED has just
    // finished transmitting.
    //
    // The negedge implementation introduces a multi-clock domain, which can
    // be potentially problematic for timing.
    
    always_ff @(negedge next_led) begin
        if(state == TRANSMITTING) begin
            if(current_led == NUM_LEDS - 1) begin
                state <= RESETTING;
                current_led <= 0;
            end
            else begin
                current_led <= current_led + 1;
            end
        end
    end
    

    /*
    // Some test code that currently a clock cycle delayed but doesn't intro.
    // a multi-clock domain
    logic next_led_prev = 0;
    logic next_led_fell;

    assign next_led_fell = (next_led_prev && !next_led);

    always_ff @(posedge clk) begin
        next_led_prev <= next_led;
        
        if(state == TRANSMITTING && next_led_fell) begin
            if(current_led == NUM_LEDS - 1) begin
                state <= RESETTING;
                current_led <= 0;
            end
            else begin
                current_led <= current_led + 1;
            end
        end
    end
    */

    assign current_led_value = led_data_snapshot[current_led];

    always_ff @(posedge clk) begin
        if((state == IDLE) && update_matrix) begin
            led_data_snapshot <= led_data;
            state <= TRANSMITTING;
        end
    end

    // Create a counter for the reset cycle
    logic [$clog2(TICKS_TO_RESET) - 1:0] reset_counter = 0;

    always_ff @(posedge clk) begin
        if(state == RESETTING) begin
            if(reset_counter == TICKS_TO_RESET - 1) begin
                reset_counter <= 0;
                state <= IDLE;
            end
            else begin
                reset_counter <= reset_counter + 1;
            end
        end
    end
    
    assign send_reset = (state == RESETTING || state == IDLE);


endmodule