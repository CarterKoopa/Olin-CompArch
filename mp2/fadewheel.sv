// Mini-Project 2 - Olin Computer Architecture FA25
// 
// Cycle through the HSV colorwheel in a clean fade once per second using the
// built-in RGB LED of the iceBlinkPico.
//
// Author: Carter Harris

module top (
    input logic clk,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);
    // Given there are 6 points at which LEDs need to change state (either
    // start increasing or decreasing), create 6 states.
    parameter NUM_STATES = 6;
    // Given the 12MHz clock and 1 second cycle time, calculate the number
    // of cycles spent in a given state.
    parameter CYCLE_TIME = 12000000 / NUM_STATES;
    // Create a parameter for the PWM interval (period), which is 100us, or 1200 cycles
    parameter PWM_INTERVAL = 1200;
     // Track maximum duty cycle, in this case, equal to the PWM period in ticks
    parameter DUTY_CYCLE_RANGE = PWM_INTERVAL;
    // Create a parameter for the amount of time spent in each PWM duty cycle increment
    parameter PWM_TIME = CYCLE_TIME / DUTY_CYCLE_RANGE;
    // Create a counter for the time spent in each region of the colorwheel
    logic [$clog2(CYCLE_TIME) - 1:0] cycle_count;
    // Do the same for the PWM duty cycle time
    logic [$clog2(PWM_TIME) - 1:0] pwm_duty_count;
    // Also create a counter for the PWM interval time
    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_interval_count;
    // Create a variable to store current state in the cycle
    // Each increment of one represents a 60 degree increment around the HSV
    // color wheel.
    logic [$clog2(NUM_STATES) - 1:0] colorwheel_current_state;
    // Create an enum to track the LED state, which will later be a function
    // of the state in the color wheel rotation.
    typedef enum {STEADY_ON, STEADY_OFF, INCREASING, DECREASING} led_state;
    // Create led_state variables for each LED
    led_state red_state;
    led_state green_state;
    led_state blue_state;
    // Create a variable to track rising and falling duty cycles
    logic [$clog2(DUTY_CYCLE_RANGE) - 1:0] duty_cycle_inc;
    logic [$clog2(DUTY_CYCLE_RANGE) - 1:0] duty_cycle_dec;
    // And whether or not the digital output should be on
    logic pwm_inc;
    logic pwm_dec;

    // Initialize LED to starting red color
    initial begin
        red_state = STEADY_ON;
        green_state = INCREASING;
        blue_state = STEADY_OFF;
        RGB_R = 1'b1;
        RGB_G = 1'b1;
        RGB_B = 1'b1;

        // Initialize state variables to zero
        cycle_count = 0;
        pwm_duty_count = 0;
        pwm_interval_count = 0;
        colorwheel_current_state = 0; 

        // Init duty cycles
        duty_cycle_inc = 0;
        duty_cycle_dec = DUTY_CYCLE_RANGE - 1;
    end

    always_comb begin
        case(colorwheel_current_state)
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

    // Sequential block to count time in each of the 6 colorwheel regions
    always_ff @(posedge clk) begin
        // If cycle time has reached, this state is finished and move
        // to the next division of the colorwheel.
        if(cycle_count == CYCLE_TIME - 1) begin
            // Reset the counter
            cycle_count <= 0;
            // Reset all PWM counters
            pwm_duty_count <= 0;
            pwm_interval_count <= 0;
            duty_cycle_inc <= 0;
            duty_cycle_dec <= DUTY_CYCLE_RANGE - 1;
            // Increment the current colorwheel state
            colorwheel_current_state <= colorwheel_current_state + 1;
            // If this was the last state of the colorwheel, reset back to the
            // first.
            if(colorwheel_current_state == NUM_STATES - 1) colorwheel_current_state <= 0;
        end
        else cycle_count <= cycle_count + 1;
    end

    // Create a sequential logic block to increment PWM duty cycle
    // duty_cycle_inc/dec store the current output duty cycle with one counting
    // up and the other counting down, respectively.
    always_ff @(posedge clk) begin
        // If the PWM increment time is reached, continue incrementing
        if(pwm_duty_count == PWM_TIME - 1) begin
            pwm_duty_count <= 0;
            duty_cycle_inc <= duty_cycle_inc + 1;
            duty_cycle_dec <= duty_cycle_dec - 1;
            // Check if the current cycle has reached the max duty cycle
            if(duty_cycle_inc == DUTY_CYCLE_RANGE - 1) begin
                duty_cycle_inc <= 0;
                duty_cycle_dec <= DUTY_CYCLE_RANGE - 1;
            end
        end
        else pwm_duty_count <= pwm_duty_count + 1;
    end

    // Sequential logic to create the 100us PWM period output
    always_ff @(posedge clk) begin
        if(pwm_interval_count == PWM_INTERVAL - 1) begin
            pwm_interval_count <= 0;
        end
        else begin
            pwm_interval_count <= pwm_interval_count + 1;
        end
    end

    // Create PWM output based on 100us period and current duty cycle
    assign pwm_inc = (pwm_interval_count > duty_cycle_inc) ? 1'b0 : 1'b1; //logic true reverse for led
    assign pwm_dec = (pwm_interval_count > duty_cycle_dec) ? 1'b0 : 1'b1;

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
                RGB_R = ~pwm_inc;
            end
            DECREASING: begin
                RGB_R = ~pwm_dec;
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
                RGB_G = ~pwm_inc;
            end
            DECREASING: begin
                RGB_G = ~pwm_dec;
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
                RGB_B = ~pwm_inc;
            end
            DECREASING: begin
                RGB_B = ~pwm_dec;
            end
            default: begin
                RGB_B = 1'b1;
            end
        endcase
    end


endmodule