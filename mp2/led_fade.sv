// LED Fade Module
//
// Given a time period (in ticks) and a maximum output value, generate a smooth
// output ramp up to that maximum value across the specified time period.
//
// Author: Carter Harris

module led_fade #(
    // The total number of ticks from zero to full output
    parameter INCREMENT_PERIOD,
    parameter NUM_STEPS,
    parameter MAX_OUTPUT,
    parameter OUTPUT_STEP = MAX_OUTPUT / NUM_STEPS,
    parameter TIME_PER_STEP = INCREMENT_PERIOD / NUM_STEPS
)(
    input logic clk,
    output logic [$clog2(MAX_OUTPUT) - 1:0] current_output_increasing,
    output logic [$clog2(MAX_OUTPUT) - 1:0] current_output_decreasing
);

    // Create a variable to count ticks between steps
    logic [$clog2(TIME_PER_STEP) - 1:0] count_to_step = 0;

    // Initialize output values
    initial begin
        current_output_increasing = 0;
        current_output_decreasing = MAX_OUTPUT - 1;
    end 

    // Create a counter to determine when it is time to increment
    always_ff @(posedge clk) begin
        if(count_to_step == TIME_PER_STEP - 1) begin
            count_to_step <= 0;
            if(current_output_increasing >= MAX_OUTPUT - OUTPUT_STEP) begin
                current_output_increasing <= 0;
                current_output_decreasing <= MAX_OUTPUT - 1;
            end
            else begin
                current_output_increasing <= current_output_increasing + OUTPUT_STEP;
                current_output_decreasing <= current_output_decreasing - OUTPUT_STEP;
            end
        end
        else begin
            count_to_step = count_to_step + 1;
    end
    end

endmodule