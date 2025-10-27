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
    parameter UPDATES_PER_SECOND = 5
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

    // Create an enum for the FSM
    typedef enum logic [2:0] {
        IDLE     = 2'b00,
        UPDATING = 2'b01,
        START    = 2'b10
    } game_states;
    // Default to the start state to initialize values
    game_states current_state = START;

    // Create counter variables
    parameter TIME_PER_FRAME = 12000000 / UPDATES_PER_SECOND;
    parameter NUM_NEIGHBORS = 8;
    parameter UPDATE_TIME = NUM_CELLS * (NUM_NEIGHBORS + 1); // Add one extra for final computation cycle
    logic [$clog2(NUM_CELLS) - 1:0] current_cell = 0;
    logic [$clog2(NUM_NEIGHBORS) - 1:0] current_neighbor = 0;


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
                if(update_game) begin
                    current_state <= update;
                end
            end
            // Main logic block. Calculate the next iteration of the board, and
            // at the end, set the output to that next version.
            UPDATING: begin
                // First level if: loop through all of the individual cells.
                // Once all cells have been updated, set the output pattern and
                // return to idle state.
                if(current_cell == NUM_CELLS - 1) begin
                    current_cell <= 0;
                    current_neighbor <= 0;
                    current_state <= IDLE;
                    current_pattern <= next_pattern;
                end
                else begin
                    // Second level: loop through all of the neighbors of the
                    // current cell.
                    // Once all neighbors are looped through, move to the next
                    // LED, while keeping track of the 2D index of the current
                    // cell to allow for easier computation elsewhere.
                    // 
                    // Intentionally no -1 in the counter to allow for an extra
                    // cycle at the end at which the cell is determined alive or
                    // dead after the total number of alive neighbors is
                    // computed.
                    if(current_neighbor == NUM_NEIGHBORS) begin
                        // Third level if: Check if this is the last column in
                        // the row, and if so, move to the next row and reset
                        // the column back to zero.
                        if(column_number == BOARD_WIDTH - 1) begin
                            column_number <= 0;
                            row_number <= row_number + 1;
                            current_cell <= current_cell + 1;
                            current_neighbor <= 0;
                            alive_neighbors <= 0;
                        end
                        // If not at the end of the column, continue to the next
                        // position within the row.
                        else begin
                            column_number <= column_number + 1;
                            current_cell <= current_cell + 1;
                            current_neighbor <= 0;
                            alive_neighbors <= 0;
                        end
                    end
                    // If we're not on the last neighbor, keep incrementing.
                    else begin
                        current_neighbor <= current_neighbor + 1;
                    end
                end
            end
        endcase
    end

    // Create variables to store the neighbor target to check so that the board
    // correctly wraps around
    logic [$clog2(BOARD_HEIGHT) - 1:0] row_back = 0;
    logic [$clog2(BOARD_HEIGHT) - 1:0] row_forward = 0;
    logic [$clog2(BOARD_WIDTH) - 1:0] col_back = 0;
    logic [$clog2(BOARD_WIDTH) - 1:0] col_forward = 0;
    
    // Based on the current cell as set above, the corresponding neighbors are
    // computed based on the principle that the graph wraps around.
    //
    // Computing the row/column point and overall index is probably unnecessary
    // with some better math, but the translation back and forth made enough
    // sense to me at the time I was writing it.
    always_comb begin
        row_back    = row_number    == 0              ? BOARD_HEIGHT - 1 : row_number - 1;
        row_forward = row_number    == BOARD_HEIGHT-1 ? 0                : row_number + 1;
        col_back    = column_number == 0              ? BOARD_WIDTH-1    : column_number - 1;
        col_forward = column_number == BOARD_WIDTH-1  ? 0                : column_number + 1;
    end

    // One neighbor is evaluated on each clock cycle. For each evaluation, if
    // the neighbor is alive (ie, a binary 1, or true) it will be added to the
    // total count of alive neighbors.
    //
    // The final 8-th neighbor case computes the next iteration of the game
    // based on the game rules and saves this in the next copy of gameboard
    // such that current version remains in-tact for further evaluation.
    logic [$clog2(NUM_CELLS - 1) - 1:0] alive_neighbors = 0;
    always_ff @(negedge clk) begin
        if(current_state == UPDATING) begin
            case(current_neighbor)
                0: begin
                    // Top left
                    alive_neighbors <= alive_neighbors + current_pattern[(row_back * BOARD_WIDTH) + col_back];
                end
                1: begin
                    // Top center
                    alive_neighbors <= alive_neighbors + current_pattern[(row_back * BOARD_WIDTH) + column_number];
                end
                2: begin
                    // Top right
                    alive_neighbors <= alive_neighbors + current_pattern[(row_back * BOARD_WIDTH) + column_forward];
                end
                3: begin
                    // Left
                    alive_neighbors <= alive_neighbors + current_pattern[(row_number * BOARD_WIDTH) + col_back];
                end
                4: begin
                    // Right
                    alive_neighbors <= alive_neighbors + current_pattern[(row_number * BOARD_WIDTH) + col_forward];
                end
                5: begin
                    // Bottom left
                    alive_neighbors <= alive_neighbors + current_pattern[(row_forward * BOARD_WIDTH) + col_back];
                end
                6: begin
                    // Bottom center
                    alive_neighbors <= alive_neighbors + current_pattern[(row_forward * BOARD_WIDTH) + column_number];
                end
                7: begin
                    // Bottom right
                    alive_neighbors <= alive_neighbors + current_pattern[(row_forward * BOARD_WIDTH) + column_forward];
                end
                8: begin
                    // This logic level checks whether, if the cell is currently
                    // alive, it should continue living.
                    if(current_pattern[(row_number * BOARD_WIDTH) + column_number]) begin
                        // Continue living if 2 or 3 living neighbors.
                        if(alive_neighbors == 2 || alive_neighbors == 3) begin
                            next_pattern[(row_number * BOARD_WIDTH) + column_number] = 1'b1;
                        end
                        else begin
                            next_pattern[(row_number * BOARD_WIDTH) + column_number] = 1'b0;
                        end
                    end
                    // This else checks if the cell should be brought alive if
                    // the cell is currently deads
                    else begin
                        // Dead cells only become alive if they have 3 neighbors
                        if(alive_neighbors == 3) begin
                            next_pattern[(row_number * BOARD_WIDTH) + column_number] = 1'b1;
                        end
                        else begin
                            next_pattern[(row_number * BOARD_WIDTH) + column_number] = 1'b0;
                        end
                    end
                end
            endcase
        end
    end



    
endmodule