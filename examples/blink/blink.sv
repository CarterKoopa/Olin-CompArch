// Blink

module top(
    input logic     clk, 
    output logic    LED
);

    // CLK frequency is 12MHz, so 6,000,000 cycles is 0.5s
    parameter BLINK_INTERVAL = 6000000;
    logic [$clog2(BLINK_INTERVAL) - 1:0] count = 0;

    initial begin
        LED = 1'b0;
    end

    always_ff @(posedge clk) begin
        if (count == BLINK_INTERVAL - 1) begin
            count <= 0;
            LED <= ~LED;
        end
        else begin
            count <= count + 1;
        end
    end

endmodule
