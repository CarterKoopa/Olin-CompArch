`timescale 10ns/10ns
`include "top.sv"

module led_tb;

    // Clock and RGB outputs
    logic clk = 0;
    logic _48b;
    logic _49a;
    logic _45a;
    logic LED;
    
    top u0 (
        .clk(clk),
        ._48b(_48b),
        ._45a(_45a),
        ._49a(_49a),
        .LED(LED)
    );

    initial begin
        $dumpfile("led_tb.vcd");
        $dumpvars(0, led_tb);
        #200000000
        //4
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule

