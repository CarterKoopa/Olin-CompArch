`include "memory.sv"

// Sine top-level module

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

    logic [8:0] address = 0;
    logic [9:0] data;

    memory #(
        .INIT_FILE      ("sine.txt")
    ) u1 (
        .clk            (clk), 
        .read_address   (address), 
        .read_data      (data)
    );

    always_ff @(posedge clk) begin
        address <= address + 1;
    end

    assign {_48b, _45a, _49a, _3b, _5a, _0a, _2a, _4a, _6a, _9b} = data;

endmodule
