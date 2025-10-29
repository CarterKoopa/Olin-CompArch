`timescale 10ns/10ns
`include "top.sv"

module game_tb;

    // Clock and RGB outputs
    logic clk = 0;
    logic _48b;
    logic _45a;
    
    top u0 (
        .clk(clk),
        ._48b(_48b),
        ._45a(_45a)
    );

    initial begin
        $dumpfile("game_tb.vcd");
        $dumpvars(0, game_tb);
        #500000000
        //4
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule

