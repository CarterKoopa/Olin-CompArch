// PWM Module
//
// Given a PWM interval in clock ticks and a PWM duty cycle output value of the
// same range, generate a PWM output square wave capable of being piped
// directly to the output of an LED (or something else).
//
// Author: Carter Harris

module pwm #(
    parameter PWM_INTERVAL
)(
    input logic clk,
    input logic [$clog2(PWM_INTERVAL) - 1:0] pwm_duty_cycle_value,
    output logic pwm_signal
);
    // Create a counter for the PWM interval time
    logic [$clog2(PWM_INTERVAL) - 1:0] pwm_interval_count = 0;

    // Sequential logic to create the 100us PWM period output
    always_ff @(posedge clk) begin
        if(pwm_interval_count == PWM_INTERVAL - 1) begin
            pwm_interval_count <= 0;
        end
        else begin
            pwm_interval_count <= pwm_interval_count + 1;
        end
    end

    // Generate a binary/square wave output based on the current duty cycle
    // value.
    // 
    // This signal is active high (which may not be the case for outputs, such
    // as the iceBlinkPico LED).
    assign pwm_signal = (pwm_interval_count > pwm_duty_cycle_value) ? 1'b0 : 1'b1;

endmodule