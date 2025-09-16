// Buttons and LEDs

module top(
    input logic     BOOT, 
    input logic     SW, 
    output logic    LED, 
    output logic    RGB_G
);

    assign LED = ~BOOT;
    assign RGB_G = SW;

endmodule
