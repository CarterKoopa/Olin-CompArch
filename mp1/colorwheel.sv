// Mini-Project 1 - Olin Computer Architecture FA25
// 
// Rotate through the HSV colorwheel in 60 degree increments using the built-in
// RGB LED of the iceBlinkPico.
//
// Author: Carter Harris

module top (
    input logic clk,
    output logic RGB_R,
    output logic RGB_G,
    output logic RGB_B
);
    // Given the 12MHz clock and the 6 color combinations, spend 2,000,000
    // cycles on each color state.
    parameter CYCLE_TIME = 2000000;
    // Create a counter object to store the cycle time with enough bits to
    // contain the given cycle time constant.
    logic [$clog2(CYCLE_TIME) - 1:0] count = 0;
    // Define a state variable for the state machine
    parameter NUM_STATES = 6;
    logic [$clog2(NUM_STATES) - 1:0] current_state = 0;

    // Finite State Machine - set the LED in a combinational logic block since
    // this assignment can be thought of as occurring in continuous time as the
    // state evolves in discrete timesteps.
    always_comb begin
        case (current_state)
                0: begin // Red
                    RGB_R = 1'b0;
                    RGB_G = 1'b1;
                    RGB_B = 1'b1;
                end
                1: begin // Yellow
                    RGB_R = 1'b0;
                    RGB_G = 1'b0;
                    RGB_B = 1'b1;
                end
                2: begin // Green
                    RGB_R = 1'b1;
                    RGB_G = 1'b0;
                    RGB_B = 1'b1;
                end
                3: begin // Cyan
                    RGB_R = 1'b1;
                    RGB_G = 1'b0;
                    RGB_B = 1'b0;
                end
                4: begin // Blue
                    RGB_R = 1'b1;
                    RGB_G = 1'b1;
                    RGB_B = 1'b0;
                end
                5: begin // Magenta
                    RGB_R = 1'b0;
                    RGB_G = 1'b1;
                    RGB_B = 1'b0;
                end
                default: begin // Default to red
                    RGB_R = 1'b0;
                    RGB_G = 1'b1;
                    RGB_B = 1'b1;
                end
            endcase
    end

    // Given the time check occurs in discrete time, use a sequential logic
    // always_ff block.
    always_ff @(posedge clk) begin
        if(count == CYCLE_TIME - 1) begin
            // Reset the count back to zero
            count <= 0;
            // Track current state with a number representing the ordered state
            // around the HSV wheel where red = 0
            current_state <= current_state + 1;
            // If all colors have been cycled through, reset back to red (zero)
            if (current_state == NUM_STATES - 1) current_state <= 0;
        end
        else begin
            // Continue ticking up
            count <= count + 1;
        end
    end

endmodule