// Finite State Machine

module fsm #(
    parameter BLINK_INTERVAL = 6000000,     // CLK freq is 12MHz, so 6,000,000 cycles is 0.5s
    parameter MAX_BLINK_COUNT = 20
)(
    input logic     clk, 
    input logic     sw1, 
    input logic     sw2, 
    output logic    red, 
    output logic    green, 
    output logic    blue
);

    // Define state variable values
    localparam GREEN = 2'b00;
    localparam BLUE = 2'b01;
    localparam RED = 2'b10;

    // Declare state variables
    logic [1:0] current_state = GREEN;
    logic [1:0] next_state;

    // Declare next output variables
    logic next_red, next_green, next_blue;

    // Declare counter variables for blinking in the BLUE state
    logic [$clog2(BLINK_INTERVAL) - 1:0] count = 0;
    logic [$clog2(MAX_BLINK_COUNT) - 1:0] blink_count = 0;
    logic blink_done;

    // Register the next state of the FSM
    always_ff @(posedge clk)
        current_state <= next_state;

    // Compute the next state of the FSM
    always_comb begin
        next_state = 2'bxx;
        case (current_state)
            GREEN:
                if (sw1 == 1'b1)
                    next_state = BLUE;
                else
                    next_state = GREEN;
            BLUE:
                if (blink_done == 1'b1)
                    next_state = RED;
                else if (sw2 == 1'b1)
                    next_state = GREEN;
                else
                    next_state = BLUE;
            RED:
                next_state = RED;
        endcase
    end

    // Register the FSM outputs
    always_ff @(posedge clk) begin
        red <= next_red;
        green <= next_green;
        blue <= next_blue;
    end

    // Compute next output values
    always_comb begin
        next_red = 1'b0;
        next_green = 1'b0;
        next_blue = 1'b0;
        case (current_state)
            GREEN:
                next_green = 1'b1;
            BLUE:
                next_blue = ~blink_count[0];
            RED:
                next_red = 1'b1;
        endcase
    end

    // Implement blink counter for flashing in the BLUE state
    always_ff @(posedge clk) begin
        if (current_state != BLUE) begin
            count <= 0;
            blink_count <= 0;
        end
        else if (count == BLINK_INTERVAL - 1) begin
            count <= 0;
            blink_count <= blink_count + 1;
        end
        else begin
            count <= count + 1;
            blink_count <= blink_count;
        end
    end

    assign blink_done = (blink_count == MAX_BLINK_COUNT) ? 1'b1 : 1'b0;

endmodule
