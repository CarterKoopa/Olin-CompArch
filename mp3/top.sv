//
// Mini-Project 3 - Game of Life
// Olin Computer Architecture FA25
//
// Top-level test module for WS2812B LED matrix
// Cycles through all 64 LEDs in Red, Blue, Green order over 15 seconds
//
// Author: Carter Harris
`include "matrix_control.sv"

module top(
    input logic clk,
    output logic LED,
    output logic _48b,  // Matrix data output
    output logic _45a,
    output logic _49a
);
    // Parameters
    parameter NUM_LEDS = 64;
    parameter NUM_COLORS = 3;
    
    // LED data array
    logic [NUM_LEDS-1:0][2:0] led_data = 0;
    
    // State variable
    logic update_matrix;
    logic send_reset;
    logic ws2812_out;
    logic on_code_signal;
    
    // Instantiate matrix controller
    matrix_control #(
        .NUM_LEDS(NUM_LEDS)
    ) matrix (
        .clk            (clk),
        .led_data       (led_data),
        .update_matrix  (update_matrix),
        .matrix_output  (ws2812_out),
        .send_reset     (send_reset),
        .on_code_signal (on_code_signal)
    );

    typedef enum logic [2:0] {
        IDLE         = 3'b001, 
        TRANSMITTING = 3'b010, 
        UPDATING     = 3'b100
    } transmitting_state;

    transmitting_state current_state = IDLE;

    // Timing variables
    // 24 bits per LED, 15 click cycles per bit
    parameter TIME_TO_UPDATE = (NUM_LEDS * 24 * 15) + 1;
    logic [$clog2(TIME_TO_UPDATE) - 1:0] matrix_update_counter = 0;

    parameter FRAMES_PER_SECOND = 30;
    parameter TICKS_PER_FRAME = (12000000 / FRAMES_PER_SECOND) - TIME_TO_UPDATE;
    logic [$clog2(TICKS_PER_FRAME) - 1:0] frame_interval_counter = 0;

    // Timing variables for LED demo code
    // 1 second = 12 million ticks
    parameter TICKS_BETWEEN_LEDS = 12000000;
    logic[$clog2(TICKS_BETWEEN_LEDS) - 1:0] led_advance_counter = 0;
    logic[$clog2(NUM_LEDS) - 1:0] num_leds_lit = 0;
    logic[$clog2(NUM_COLORS) - 1:0] num_colors_lit = 0;

    logic [$clog2(NUM_LEDS) - 1:0] led_update_counter = 0;

    always_ff @(posedge clk) begin
        if(led_advance_counter == TICKS_BETWEEN_LEDS - 1) begin
            led_advance_counter <= 0;
            if(num_leds_lit == NUM_LEDS - 1) begin
                num_leds_lit <= 0;
                if(num_colors_lit == NUM_COLORS - 1) begin
                    num_colors_lit <= 0;
                end
                else begin
                    num_colors_lit <= num_colors_lit + 1;
                end
            end
            else begin
                num_leds_lit <= num_leds_lit + 1;
            end
        end
        else begin
            led_advance_counter <= led_advance_counter + 1;
        end
    end

    always_ff @(posedge clk) begin
        case(current_state)
            IDLE: begin
                if(frame_interval_counter == TICKS_PER_FRAME - 1) begin
                    frame_interval_counter <= 0;
                    current_state <= UPDATING;
                end
                else begin
                    frame_interval_counter <= frame_interval_counter + 1;
                end
            end
            UPDATING: begin
                if(led_update_counter == NUM_LEDS - 1) begin
                    led_update_counter <= 0;
                    current_state <= TRANSMITTING;
                end
                else begin
                    led_update_counter <= led_update_counter + 1;
                end
            end
            TRANSMITTING: begin
                if(matrix_update_counter == TIME_TO_UPDATE - 1) begin
                    matrix_update_counter <= 0;
                    current_state <= IDLE;
                end
                else begin
                    matrix_update_counter <= matrix_update_counter + 1;
                end
            end
        endcase
    end

    assign update_matrix = (current_state == TRANSMITTING) ? 1'b1 : 1'b0;

    always_ff @(negedge clk) begin
        if(current_state == UPDATING) begin
            if(num_leds_lit > led_update_counter) begin
                case(num_colors_lit)
                    0: begin
                        led_data[led_update_counter] <= 3'b100;
                    end
                    1: begin
                        led_data[led_update_counter] <= 3'b110;
                    end
                    2: begin
                        led_data[led_update_counter] <= 3'b111;
                    end
                endcase
            end
        end
    end

    assign _48b = ws2812_out;
    assign _45a = on_code_signal;
    assign RGB_R = 1'b0;//(current_state == IDLE);

endmodule