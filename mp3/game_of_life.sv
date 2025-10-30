//
// Mini-Project 3 - Game of Life
// Olin Computer Architecture FA25
//
// Simulate Conway's Game of Life across a grid where edges warp around.
//
// Author: Carter Harris

module game_of_life #(
    parameter BOARD_WIDTH = 8,
    parameter BOARD_HEIGHT = 8,
    parameter UPDATES_PER_SECOND = 2
)
(
    input logic clk,
    input logic update_game,
    input logic [(BOARD_HEIGHT*BOARD_WIDTH) -1:0] starting_pattern,
    output logic [(BOARD_HEIGHT*BOARD_WIDTH) -1:0] current_pattern
);
    
    // Start defining game parameters
    parameter NUM_CELLS = BOARD_HEIGHT * BOARD_WIDTH;

    // Create a secondary logical value to store the next iteration of the game
    logic [(BOARD_HEIGHT*BOARD_WIDTH) -1:0] next_pattern = 0;

    // Create an enum for states of the state machine.
    typedef enum logic [1:0] {
        IDLE     = 2'b00,
        UPDATING = 2'b01,
        START    = 2'b10
    } game_states;
    // Default to the start state to initialize values
    game_states current_state = START;

    // Create counter variables
    parameter TIME_PER_FRAME = 12000000 / UPDATES_PER_SECOND;
    parameter NUM_NEIGHBORS = 8;
    parameter UPDATE_TIME = NUM_CELLS + 1; // Add one extra for final computation cycle
    logic [$clog2(NUM_CELLS + 1) - 1:0] current_cell = 0;
    logic [$clog2(NUM_CELLS - 1) - 1:0] alive_neighbors = 0;

    logic current_bit_status;

    // Count position in the grid for updating
    logic [$clog2(BOARD_WIDTH) - 1:0] column_number = 0;
    logic [$clog2(BOARD_HEIGHT) - 1:0] row_number = 0;
    
    // Main logic block and finite state machine
    always_ff @(posedge clk) begin
        case(current_state)
            // START: the default value that only runs at boot and sets the
            // current pattern to the starting pattern, then defaults to idle.
            START: begin
                current_pattern <= starting_pattern;
                current_state <= IDLE;
            end
            // IDLE: do nothing, count up until it is time to compute the next
            // step.
            IDLE: begin
                next_pattern <= 0;
                if(update_game) begin
                    current_state <= UPDATING;
                end
            end
            // Main logic block. Calculate the next iteration of the board, and
            // at the end, set the output to that next version.
            UPDATING: begin
                // First level if: loop through all of the individual cells.
                // Once all cells have been updated, set the output pattern and
                // return to idle state.
                if(current_cell == NUM_CELLS) begin
                    current_cell <= 0;
                    current_state <= IDLE;
                    current_pattern <= next_pattern;
                    column_number <= 0;
                    row_number <= 0;
                end
                else begin
                    // Third level if: Check if this is the last column in
                    // the row, and if so, move to the next row and reset
                    // the column back to zero.
                    next_pattern[(row_number * BOARD_WIDTH) + column_number] <= current_bit_status;
                    if(column_number == BOARD_WIDTH - 1) begin
                        column_number <= 0;
                        row_number <= row_number + 1;
                        current_cell <= current_cell + 1;
                        alive_neighbors <= 0;
                    end
                    // If not at the end of the column, continue to the next
                    // position within the row.
                    else begin
                        column_number <= column_number + 1;
                        current_cell <= current_cell + 1;
                        alive_neighbors <= 0;
                    end
                end
                end
        endcase
    end

    // Create variables to store the neighbor target to check so that the board
    // correctly wraps around
    logic [$clog2(BOARD_HEIGHT) - 1:0] row_back;
    logic [$clog2(BOARD_HEIGHT) - 1:0] row_forward;
    logic [$clog2(BOARD_WIDTH) - 1:0] column_back;
    logic [$clog2(BOARD_WIDTH) - 1:0] column_forward;
    
    // Based on the current cell as set above, the corresponding neighbors are
    // computed based on the principle that the graph wraps around.
    //
    // Computing the row/column point and overall index is probably unnecessary
    // with some better math, but the translation back and forth made enough
    // sense to me at the time I was writing it.
    always_comb begin
        row_back       = row_number    == 0              ? BOARD_HEIGHT - 1 : row_number - 1;
        row_forward    = row_number    == BOARD_HEIGHT-1 ? 0                : row_number + 1;
        column_back    = column_number == 0              ? BOARD_WIDTH-1    : column_number - 1;
        column_forward = column_number == BOARD_WIDTH-1  ? 0                : column_number + 1;
    end

    // One cell in the pattern is evaluated per clock cycle. When the current 
    // cell changes, the number of neighbors is computed, and then the resulting
    // alive/dead status is stored in the next pattern array.
    always_comb begin
        if(current_state == UPDATING) begin
            // Calculate all 8 neighbors at once
            alive_neighbors = current_pattern[(row_back * BOARD_WIDTH) + column_back] +      // Top left
                            current_pattern[(row_back * BOARD_WIDTH) + column_number] +     // Top center
                            current_pattern[(row_back * BOARD_WIDTH) + column_forward] +    // Top right
                            current_pattern[(row_number * BOARD_WIDTH) + column_back] +     // Left
                            current_pattern[(row_number * BOARD_WIDTH) + column_forward] +  // Right
                            current_pattern[(row_forward * BOARD_WIDTH) + column_back] +    // Bottom left
                            current_pattern[(row_forward * BOARD_WIDTH) + column_number] +  // Bottom center
                            current_pattern[(row_forward * BOARD_WIDTH) + column_forward];  // Bottom right
            
            // Determine next state for this cell
            if(current_pattern[(row_number * BOARD_WIDTH) + column_number]) begin
                current_bit_status = (alive_neighbors == 2 || alive_neighbors == 3);
            end 
            else begin
                current_bit_status = (alive_neighbors == 3);
            end
        end
        // When outside of the updating cell, these variables are unused and
        // held at zero.
        else begin
            current_bit_status = 0;
            alive_neighbors = 0;
        end
    end
    
endmodule