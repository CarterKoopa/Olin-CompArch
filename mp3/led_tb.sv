`timescale 10ns/10ns
`include "top.sv"

module led_tb;

    // Clock and RGB outputs
    logic clk = 0;
    logic _48b;
    
    top u0 (
        .clk(clk),
        ._48b(_48b)
    );

    initial begin
        $dumpfile("led_tb.vcd");
        $dumpvars(0, led_tb);
        #400000000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule

