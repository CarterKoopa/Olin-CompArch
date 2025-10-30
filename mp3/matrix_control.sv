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
    input logic [NUM_LEDS-1:0][2:0] led_data,
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
    logic [NUM_LEDS-1:0][2:0] led_data_snapshot = 0;

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
    typedef enum logic [2:0] {
        IDLE         = 3'b001,
        TRANSMITTING = 3'b010,
        RESETTING    = 3'b100
        } matrix_state;
    matrix_state state = IDLE;

    // Because the higher level modules provide a binary on-off for each LED
    // color, translate that into a 24-bit value of roughly half brightness for
    // transmission to the LED.
    always_comb begin
        case(led_data_snapshot[current_led])
            3'b000: begin
                current_led_value = 24'h000000;
            end
            3'b001: begin
                current_led_value = 24'h000080;
            end
            3'b011: begin
                current_led_value = 24'h008080;
            end
            3'b111: begin
                current_led_value = 24'h808080;
            end
            3'b110: begin
                current_led_value = 24'h808000;
            end
            3'b100: begin
                current_led_value = 24'h800000;
            end
            3'b010: begin
                current_led_value = 24'h008000;
            end
            3'b101: begin
                current_led_value = 24'h800080;
            end
            default: begin
                current_led_value = 24'h000000;
            end
        endcase
    end

    // Create a counter for the reset cycle
    logic [$clog2(TICKS_TO_RESET) - 1:0] reset_counter = 0;
    parameter TIME_PER_BIT = 15;
    logic [$clog2(TIME_PER_BIT) - 1:0] last_bit_timer = 0;
    logic last_bit = 1'b0;

    // Main state machine.
    always_ff @(posedge clk) begin
        case(state)
            // When the matrix is resetting (ie, after a complete transmission),
            // the output is held at zero to ensure the signal stays low long
            // enough for the WS2812 LEDs to stay off. 
            RESETTING: begin
                if(reset_counter == TICKS_TO_RESET - 1) begin
                    reset_counter <= 0;
                    state <= IDLE;
                end
                else begin
                    reset_counter <= reset_counter + 1;
                end
            end
            // Once a sufficient off-time to reset has been reached, the state
            // translates to IDLE and awaits a signal to update.
            // A snapshot of the data is taken upon moving to the next state
            // to ensure that data is not changed mid-transmission.
            IDLE: begin
                if(update_matrix) begin
                    led_data_snapshot <= led_data;
                    state <= TRANSMITTING;
                end
            end
            // Once transmitting, the LED data is sent one by one to the LED
            // controller. The loop tracks when the controller is sending
            // the last bit of the LED and prepares to update to the next bit.
            TRANSMITTING: begin
                if(next_led) begin
                    last_bit = 1'b1;
                end
                if(last_bit) begin
                    if(last_bit_timer == TIME_PER_BIT - 1) begin
                        if(current_led == NUM_LEDS - 1) begin
                            state <= RESETTING;
                            current_led <= 0;
                            last_bit_timer <= 0;
                            last_bit = 1'b0;
                        end
                        else begin
                            current_led <= current_led + 1;
                            last_bit_timer <= 0;
                            last_bit = 1'b0;
                        end
                    end
                    else begin
                        last_bit_timer <= last_bit_timer + 1;
                    end
                end
            end
        endcase
    end
    
    // While the reset state is nominally the only place where the output has
    // to be zero, it is held at zero throughout the idle period too to prevent
    // any unintended or half-transmissions.
    assign send_reset = (state == RESETTING || state == IDLE);


endmodule