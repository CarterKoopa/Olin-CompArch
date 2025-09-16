// Sawtooth

module top(
    input logic     clk, 
    output logic    _9b,    // D0
    output logic    _6a,    // D1
    output logic    _4a,    // D2
    output logic    _2a,    // D3
    output logic    _0a,    // D4
    output logic    _5a,    // D5
    output logic    _3b,    // D6
    output logic    _49a,   // D7
    output logic    _45a,   // D8
    output logic    _48b    // D9
);

    localparam PRESCALAR = 10;

    logic time_to_count = 1'b0;
    logic [3:0] prescalar_count = 0;
    logic [9:0] count = 0;

    always_ff @(posedge clk) begin
        if (prescalar_count == PRESCALAR - 1) begin
            prescalar_count <= 0;
            time_to_count <= 1'b1;
        end
        else begin
            prescalar_count <= prescalar_count + 1;
            time_to_count <= 1'b0;
        end
    end

    always_ff @(posedge time_to_count) begin
        count <= count + 1;
    end

    assign {_48b, _45a, _49a, _3b, _5a, _0a, _2a, _4a, _6a, _9b} = count & 10'b1111111111;

endmodule
