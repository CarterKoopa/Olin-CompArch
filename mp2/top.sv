// Mini-Project 2 - Olin Computer Architecture FA25
// 
// Cycle through the HSV colorwheel in a clean fade once per second using the
// built-in RGB LED of the iceBlinkPico.
//
// This implementation relies on two submodules to:
//      a) generate a smooth ramp up to a target output value over a given
//         time span.
//      b) generate a PWM output based on a given input value & range
//
// Author: Carter Harris
`include "led_fade.sv"
`include "pwm.sv"

module top (
    input logic clk,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);
    //
    // CONFIGURE STATIC PARAMETERS
    //

    // The complete cycle should take 1 second, given the 12MHz clock
    parameter CYCLE_TIME = 12000000;
    // The HSV colorwheel has 6 distinct states
    parameter NUM_STATES = 6;
    // Track the per-state time spent
    parameter TICKS_PER_STATE = CYCLE_TIME / NUM_STATES;
    // The PWM period, or interval, is 100us, or 1200 ticks. This additionally
    // defines the range of output values for the LED's PWM signal given the
    // signal is generated via comparison to the number of ticks through each a
    // given period the signal is.
    parameter PWM_INTERVAL = 1200;
    // Somewhat-arbitrarily define the number of steps taken to reach the
    // maximum LED output value;
    parameter NUM_STEPS = 200;

    // 
    // CONFIGURE STATE-TRACKING VARIABLES
    //

    // Create a custom type to track the possible states of each led
    typedef enum {STEADY_ON, STEADY_OFF, INCREASING, DECREASING} led_state;
    // Create led_state variables for each LED
    led_state red_state;
    led_state green_state;
    led_state blue_state;

    //
    // CONFIGURE COUNTERS
    //

    // Track the current output value
    logic [$clog2(PWM_INTERVAL) - 1:0] output_value_increasing;
    logic [$clog2(PWM_INTERVAL) - 1:0] output_value_decreasing;
    // Count ticks for a given state
    logic [$clog2(TICKS_PER_STATE) - 1:0] state_count = 0;
    // Track the actual current state
    logic [$clog2(NUM_STATES) - 1:0] current_state = 0;

    //
    // CONFIGURE OUTPUTS
    //
    logic pwm_signal_increasing;
    logic pwm_signal_decreasing;

    //
    // CONFIGURE SUBMODULES
    //
    led_fade #(
        .INCREMENT_PERIOD   (TICKS_PER_STATE),
        .NUM_STEPS          (NUM_STEPS),
        .MAX_OUTPUT         (PWM_INTERVAL)
    ) u1 (
        .clk                        (clk),
        .current_output_increasing  (output_value_increasing),
        .current_output_decreasing  (output_value_decreasing)
    );

    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u2 (
        .clk                    (clk),
        .pwm_duty_cycle_value   (output_value_increasing),
        .pwm_signal             (pwm_signal_increasing)
    );

    pwm #(
        .PWM_INTERVAL   (PWM_INTERVAL)
    ) u3 (
        .clk                    (clk),
        .pwm_duty_cycle_value   (output_value_decreasing),
        .pwm_signal             (pwm_signal_decreasing)
    );

    //
    // BEGIN NEW MODULE
    //

    // Track & increment the current state
    always_ff @(posedge clk) begin
        if(state_count == TICKS_PER_STATE - 1) begin
            state_count <= 0;
            if(current_state == NUM_STATES - 1) begin
                current_state <= 0;
            end
            else begin
                current_state <= current_state + 1;
            end
        end
        else begin
            state_count <= state_count + 1;
        end
    end

    // Set the mode of each LED based on the current state
    always_comb begin
        case(current_state)
            0: begin // 0-60 degrees on HSV wheel
                red_state = STEADY_ON;
                green_state = INCREASING;
                blue_state = STEADY_OFF;
            end
            1: begin // 60-120 degrees on HSV wheel
                red_state = DECREASING;
                green_state = STEADY_ON;
                blue_state = STEADY_OFF;
            end
            2: begin // 120-180 degrees on HSV wheel
                red_state = STEADY_OFF;
                green_state = STEADY_ON;
                blue_state = INCREASING;
            end
            3: begin // 180-240 degrees on HSV wheel
                red_state = STEADY_OFF;
                green_state = DECREASING;
                blue_state = STEADY_ON;
            end
            4: begin // 240-300 degrees on HSV wheel
                red_state = INCREASING;
                green_state = STEADY_OFF;
                blue_state = STEADY_ON;
            end
            5: begin // 300-360 degrees on HSV wheel
                red_state = STEADY_ON;
                green_state = STEADY_OFF;
                blue_state = DECREASING;
            end
            default: begin // Default to 0 degree state
                red_state = STEADY_ON;
                green_state = INCREASING;
                blue_state = STEADY_OFF;
            end
        endcase
    end

    // Set the LED outputs based on the current status of each LED
    always_comb begin
        case(red_state)
            STEADY_ON: begin
                RGB_R = 1'b0;
            end
            STEADY_OFF: begin
                RGB_R = 1'b1;
            end
            INCREASING: begin
                RGB_R = ~pwm_signal_increasing;
            end
            DECREASING: begin
                RGB_R = ~pwm_signal_decreasing;
            end
            default: begin
                RGB_R = 1'b1;
            end
        endcase
    end
    always_comb begin
        case(green_state)
            STEADY_ON: begin
                RGB_G = 1'b0;
            end
            STEADY_OFF: begin
                RGB_G = 1'b1;
            end
            INCREASING: begin
                RGB_G = ~pwm_signal_increasing;
            end
            DECREASING: begin
                RGB_G = ~pwm_signal_decreasing;
            end
            default: begin
                RGB_G = 1'b1;
            end
        endcase
    end
    always_comb begin
        case(blue_state)
            STEADY_ON: begin
                RGB_B = 1'b0;
            end
            STEADY_OFF: begin
                RGB_B = 1'b1;
            end
            INCREASING: begin
                RGB_B = ~pwm_signal_increasing;
            end
            DECREASING: begin
                RGB_B = ~pwm_signal_decreasing;
            end
            default: begin
                RGB_B = 1'b1;
            end
        endcase
    end



endmodule