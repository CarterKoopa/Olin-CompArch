`timescale 10ns/10ns
`include "fadewheel.sv"

module fadewheel_tb;

    parameter PWM_INTERVAL = 1200;

    // Clock and RGB outputs
    logic clk = 0;
    logic RGB_R, RGB_G, RGB_B;
    
    top u0 (
        .clk(clk),
        .RGB_R(RGB_R),
        .RGB_G(RGB_G),
        .RGB_B(RGB_B)
    );

    initial begin
        $dumpfile("fadewheel.vcd");
        $dumpvars(0, fadewheel_tb);
        #120000000
        $finish;
    end

    always begin
        #4
        clk = ~clk;
    end

endmodule

