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
    input logic [2:0] color,
    output logic _48b  // Matrix data output
);
    // Parameters
    parameter BOARD_WIDTH = 8;
    parameter BOARD_HEIGHT = 8;
    parameter NUM_LEDS = BOARD_HEIGHT * BOARD_WIDTH;
    
    // LED data array
    logic [NUM_LEDS-1:0][2:0] led_data = 0;

    // Game pattern array
    logic [NUM_LEDS - 1:0] pattern = 0;
    
    // State variable
    logic update_matrix;
    logic update_game;
    logic ws2812_out;
    
    // Instantiate matrix controller
    matrix_control #(
        .NUM_LEDS(NUM_LEDS)
    ) matrix (
        .clk            (clk),
        .led_data       (led_data),
        .update_matrix  (update_matrix),
        .matrix_output  (ws2812_out),
    );


    game_of_life #(
        .BOARD_WIDTH        (BOARD_WIDTH),
        .BOARD_HEIGHT       (BOARD_HEIGHT),
        .UPDATES_PER_SECOND (5)
    ) game (
        .clk              (clk),
        .update_game      (update_game),
        .starting_pattern (64'b0000000001100000010000000000100000011000000000000000000000000000),
        .current_pattern  (current_pattern)
    );

    typedef enum logic [2:0] {
        IDLE          = 3'b001, 
        TRANSMITTING  = 3'b010, 
        UPDATE_MATRIX = 3'b100,
        UPDATE_GAME   = 3'b111,
    } transmitting_state;

    transmitting_state current_state = IDLE;

    // Timing variables
    // 24 bits per LED, 15 click cycles per bit
    parameter TIME_TO_UPDATE = (NUM_LEDS * 24 * 15) + 1;
    logic [$clog2(TIME_TO_UPDATE) - 1:0] matrix_update_counter = 0;

    parameter FRAMES_PER_SECOND = 30;
    parameter TICKS_PER_FRAME = (12000000 / FRAMES_PER_SECOND) - TIME_TO_UPDATE;
    logic [$clog2(TICKS_PER_FRAME) - 1:0] frame_interval_counter = 0;

    //
    // 9 = 8 neighbors + 1 logic clock cycle
    // Plus one cycle of lag for the game to update after flag set
    parameter TIME_TO_UPDATE_GAME = (NUM_LEDS * (9)) + 1;
    logic [$clog2(TIME_TO_UPDATE_GAME) - 1:0] game_update_counter = 0;


    always_ff @(posedge clk) begin
        case(current_state)
            IDLE: begin
                if(frame_interval_counter == TICKS_PER_FRAME - 1) begin
                    frame_interval_counter <= 0;
                    current_state <= UPDATE_GAME;
                end
                else begin
                    frame_interval_counter <= frame_interval_counter + 1;
                end
            end
            UPDATE_GAME: begin
                if(game_update_counter == TIME_TO_UPDATE_GAME - 1) begin
                    game_update_counter <= 0;
                    current_state <= UPDATE_MATRIX;
                end
                else begin
                    game_update_counter <= game_update_counter + 1;
                end
            end
             UPDATE_MATRIX: begin
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

     always_ff @(negedge clk) begin
        if(current_state == UPDATE_MATRIX) begin
            if(current_pattern[matrix_update_counter]) begin
                case(color)
                    3'b100: begin
                        led_data[led_update_counter][2:0] <= 3'b100;
                    end
                    3'b010: begin
                        led_data[led_update_counter][2:0] <= 3'b110;
                    end
                    3'b001: begin
                        led_data[led_update_counter][2:0] <= 3'b111;
                    end
                endcase
            end
        end
    end

    assign update_matrix = (current_state == TRANSMITTING);

    assign update_game = (current_state == UPDATE_GAME)

    assign _48b = ws2812_out;

endmodule