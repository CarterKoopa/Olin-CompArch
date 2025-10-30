//
// Mini-Project 3 - Game of Life
// Olin Computer Architecture FA25
//
// Top-level test module for WS2812B LED matrix
// Cycles through all 64 LEDs in Red, Blue, Green order over 15 seconds
//
// Author: Carter Harris
`include "matrix_control.sv"
`include "game_of_life.sv"

module top(
    input logic clk,
    output logic _48b  // Matrix data output
);
    // Declare parameters related to the matrix & game size
    parameter BOARD_WIDTH = 8;
    parameter BOARD_HEIGHT = 8;
    parameter NUM_LEDS = BOARD_HEIGHT * BOARD_WIDTH;
    
   // Data storage arrays
   // First store the LED data and the output data for a single LED as it is
   // updated.
   // The LED data array is stored in 2D: there are NUM_LEDS slices and 3 bits
   // per slice to store a value for the R, G, and B LED. Currently, brightness
   // is not able to be controlled through this method, but this made the code
   // much more synthesizable.
    logic [NUM_LEDS-1:0][2:0] led_data = 0;
    logic [2:0] current_led_data = 0;

    // Logic arrays to store the current state of the Game of Life. There are
    // three for the three independent games played on each of the RGB color
    // channels.
    logic [63:0] current_pattern_R;
    logic [63:0] current_pattern_G;
    logic [63:0] current_pattern_B;
    
    // State variables to control timing with the various submodules.
    logic matrix_transmit;
    logic update_game;

    // Output logic variable for the WS2812b matrix control code.
    logic ws2812_out;
    
    // First instantiate the matrix controller, which under the hood, also
    // creates a LED controller.
    //
    // This matrix controller takes as input the LED data stream described
    // above, along with a flag variable of when it is safe to update the matrix
    // without worry of the data changing mid-update.
    matrix_control #(
        .NUM_LEDS(NUM_LEDS)
    ) matrix (
        .clk            (clk),
        .led_data       (led_data),
        .update_matrix  (matrix_transmit),
        .matrix_output  (ws2812_out)
    );

    // Next, the starting patterns are read from memb files in binary format.
    // The files are structure as 8, 8-bit words split by lines.
    //
    // After being read in from the files, the words are concatenated to create
    // patterns as expected in the game_of_life module and described above.
    // 
    // Memory arrays for loading patterns (8 x 8-bit words in binary)
    logic [7:0] pattern_mem_R [0:7];
    logic [7:0] pattern_mem_G [0:7];
    logic [7:0] pattern_mem_B [0:7];
    
    // Logic array to store concatenated words after they're read
    logic [63:0] starting_pattern_R;
    logic [63:0] starting_pattern_G;
    logic [63:0] starting_pattern_B;
    
    // This block actually loads and concatenates the memory files.
    //
    // This initial block runs at synthesis, so all of the data is then stored
    // on the FPGA without having to do any sort of file copy-over.
    initial begin
        $readmemb("start_patterns/pattern_R.memb", pattern_mem_R);
        $readmemb("start_patterns/pattern_G.memb", pattern_mem_G);
        $readmemb("start_patterns/pattern_B.memb", pattern_mem_B);
        
        // Manually concat: not the most pretty or efficient, but I couldn't get
        // much better to work with fancy packing operators.
        starting_pattern_R = {pattern_mem_R[7], pattern_mem_R[6],
                              pattern_mem_R[5], pattern_mem_R[4],
                              pattern_mem_R[3], pattern_mem_R[2],
                              pattern_mem_R[1], pattern_mem_R[0]
                            };
        starting_pattern_G = {pattern_mem_G[7], pattern_mem_G[6],
                              pattern_mem_G[5], pattern_mem_G[4],
                              pattern_mem_G[3], pattern_mem_G[2],
                              pattern_mem_G[1], pattern_mem_G[0]
                            };
        starting_pattern_B = {pattern_mem_B[7], pattern_mem_B[6],
                              pattern_mem_B[5], pattern_mem_B[4],
                              pattern_mem_B[3], pattern_mem_B[2],
                              pattern_mem_B[1], pattern_mem_B[0]
                            };
    end

    // Instantiate the Game of Life modules. One module is created for each of
    // the three independent games running at one time. As input, these take the
    // starting and current patterns alongside a flag telling the game when it
    // is safe to update. 
    game_of_life #(
        .BOARD_WIDTH        (BOARD_WIDTH),
        .BOARD_HEIGHT       (BOARD_HEIGHT),
        .UPDATES_PER_SECOND (3)
    ) game_R (
        .clk              (clk),
        .update_game      (update_game),
        .starting_pattern (starting_pattern_R),
        .current_pattern  (current_pattern_R)
    );

    game_of_life #(
        .BOARD_WIDTH        (BOARD_WIDTH),
        .BOARD_HEIGHT       (BOARD_HEIGHT),
        .UPDATES_PER_SECOND (3)
    ) game_G (
        .clk              (clk),
        .update_game      (update_game),
        .starting_pattern (starting_pattern_G),
        .current_pattern  (current_pattern_G)
    );

    game_of_life #(
        .BOARD_WIDTH        (BOARD_WIDTH),
        .BOARD_HEIGHT       (BOARD_HEIGHT),
        .UPDATES_PER_SECOND (3)
    ) game_B (
        .clk              (clk),
        .update_game      (update_game),
        .starting_pattern (starting_pattern_B),
        .current_pattern  (current_pattern_B)
    );

    // Define a state variable with defined one-hot binary values for easier
    // debugging.
    typedef enum logic [2:0] {
        IDLE          = 3'b001, 
        TRANSMITTING  = 3'b010, 
        UPDATE_LED_DATA = 3'b100,
        UPDATE_GAME   = 3'b111
    } transmitting_state;

    // Start in idle state.
    transmitting_state current_state = IDLE;

    // Timing variables
    // This parameter manually calculates the time needed to send out the
    // signal to the WS2812B LEDs based upon the 24-bit signal sent to each
    // LED where each bit takes 15 clock cycles.
    //
    // There's definitely an opportunity for refactoring here to avoid magic
    // numbers and potential inconsistencies between the matrix controller
    // file and this controller file, but that's for another day.
    parameter BITS_PER_LED = 24;
    parameter TICKS_PER_BIT = 15;
    parameter TIME_TO_UPDATE = (NUM_LEDS * BITS_PER_LED * TICKS_PER_BIT) + 1;
    logic [$clog2(TIME_TO_UPDATE) - 1:0] transmitting_counter = 0;

    // The data for each LED is translated from the pattern output by
    // game_of_life into valid LED data for the matrix_controller one-by-one
    // in an individual clock cycle to avoid race conditions and for loops.
    // As such, create a timer equal to the number of LEDs/cells to track
    // this updating.
    logic [$clog2(NUM_LEDS) - 1:0] update_led_data_counter = 0;

    // Create a counter for the UPDATE_GAME state. Each cell is also updated
    // one by one, so this counter also is equal to the size of NUM_LEDS, plus
    // one setup clock cycle.
    //
    // Having this parameter set incorrectly can cause the game module to get
    // stuck in a loop of updating and eventually stop updating mid-loop.
    // TODO: add some sort of protection within game_of_life to prevent this
    // from happening. I believe that currently this behavior is occurring
    // because the counter is just rolling over in game_of_life when the update
    // input flag remains high. It works though.
    parameter TIME_TO_UPDATE_GAME = NUM_LEDS + 1;
    logic [$clog2(TIME_TO_UPDATE_GAME) - 1:0] game_update_counter = 0;

    // Based upon the target frame rate, calculate idle interval between frame
    // updates, taking in account how long it takes to actually update and
    // complete the other states of the FSM.
    parameter FRAMES_PER_SECOND = 6;
    parameter TICKS_PER_FRAME = (12000000 / FRAMES_PER_SECOND) - TIME_TO_UPDATE;
    logic [$clog2(TICKS_PER_FRAME) - 1:0] frame_interval_counter = 0;


    // Main state machine timing. Alternate between the states, moving from
    // one to the next as the timer expires.
    //
    // It would likely be a better use of FPGA resources to create a single
    // timer capable of holding the largest necessary count value and then
    // reset this timer at each stage and just compare the timer to different
    // conditions. For now, however, it works.
    always_ff @(posedge clk) begin
        case(current_state)
            // IDLE state: time between other states when nothing is updating
            // or happening. Time dependant on frame rate.
            IDLE: begin
                if(frame_interval_counter == TICKS_PER_FRAME - 1) begin
                    frame_interval_counter <= 0;
                    current_state <= UPDATE_GAME;
                end
                else begin
                    frame_interval_counter <= frame_interval_counter + 1;
                end
            end
            // Update game: the game modules update for the next iteration.
            // pattern arrays are updated.
            UPDATE_GAME: begin
                if(game_update_counter == TIME_TO_UPDATE_GAME - 1) begin
                    game_update_counter <= 0;
                    current_state <= UPDATE_LED_DATA;
                end
                else begin
                    game_update_counter <= game_update_counter + 1;
                end
            end
            // LED update phase: the pattern data is translated to LED data.
             UPDATE_LED_DATA: begin
                if(update_led_data_counter == NUM_LEDS - 1) begin
                    led_data[update_led_data_counter] <= current_led_data;
                    update_led_data_counter <= 0;
                    current_state <= TRANSMITTING;
                end
                else begin
                    led_data[update_led_data_counter] <= current_led_data;
                    update_led_data_counter <= update_led_data_counter + 1;
                end
            end
            // Transmitting phase: the LED data is transmitted by the matrix
            // controller.
            TRANSMITTING: begin
                if(transmitting_counter == TIME_TO_UPDATE - 1) begin
                    transmitting_counter <= 0;
                    current_state <= IDLE;
                end
                else begin
                    transmitting_counter <= transmitting_counter + 1;
                end
            end
        endcase
    end

    // When in the update_led_data stage, this block actually updates the
    // LED data array from the pattern array as the current_led changes.
    //
    // This builds data bit-by-bit, which you really aren't supposed to be doing
    // in a combinational logic block, but the combinational logic avoids the
    // problem of race conditions when both reading/writing data on a positive
    // clock edge with sequential logic. To bridge this gap and avoid latch
    // conditions with the other bits in the array, the combinational block
    // instead just updates a single bit, and the bit is stored back in the
    // larger array inside the sequential timer block. 
    always_comb begin
        if(current_state == UPDATE_LED_DATA) begin
            current_led_data = {
            current_pattern_R[update_led_data_counter],
            current_pattern_G[update_led_data_counter],
            current_pattern_B[update_led_data_counter]
            };
        end
        else begin
            current_led_data = 0;
        end
    end
    

    // Assign with combinational logic the flags to the other modules based
    // upon the current state of the state machine.
    assign matrix_transmit = (current_state == TRANSMITTING);
    assign update_game = (current_state == UPDATE_GAME);

    // Assign the actual matrix output pin.
    assign _48b = ws2812_out;

endmodule