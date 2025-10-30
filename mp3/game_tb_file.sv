`timescale 10ns/10ns
`include "top.sv"

module game_tb_file;
    // Clock and RGB outputs
    logic clk = 0;
    logic _48b;
    logic [63:0] pattern_R;
    logic [63:0] pattern_G;
    logic [63:0] pattern_B;
    
    // Previous values for change detection
    logic [63:0] prev_pattern_R = 64'h0;
    logic [63:0] prev_pattern_G = 64'h0;
    logic [63:0] prev_pattern_B = 64'h0;
    
    // Change counters
    integer change_count_R = 0;
    integer change_count_G = 0;
    integer change_count_B = 0;
    
    // File handles
    integer file_R, file_G, file_B;
    
    top u0 (
        .clk(clk),
        ._48b(_48b),
        .current_pattern_R(pattern_R),
        .current_pattern_G(pattern_G),
        .current_pattern_B(pattern_B)
    );
    
    initial begin
        $dumpfile("game_tb_file.vcd");
        $dumpvars(0, game_tb_file);
        
        // Open CSV files for writing
        file_R = $fopen("tb-output/pattern_R.csv", "w");
        file_G = $fopen("tb-output/pattern_G.csv", "w");
        file_B = $fopen("tb-output/pattern_B.csv", "w");
        
        // Write headers
        $fwrite(file_R, "Change,Time,Pattern_Hex,Pattern_Binary\n");
        $fwrite(file_G, "Change,Time,Pattern_Hex,Pattern_Binary\n");
        $fwrite(file_B, "Change,Time,Pattern_Hex,Pattern_Binary\n");
        
        #100000000
        
        // Close files at end of simulation
        $fclose(file_R);
        $fclose(file_G);
        $fclose(file_B);
        
        $finish;
    end
    
    always begin
        #4
        clk = ~clk;
    end
    
    // Monitor pattern_R changes
    always @(pattern_R) begin
        if (pattern_R !== prev_pattern_R) begin
            $fwrite(file_R, "%0d,%0t,%h,%b\n", change_count_R, $time, pattern_R, pattern_R);
            prev_pattern_R = pattern_R;
            change_count_R = change_count_R + 1;
        end
    end
    
    // Monitor pattern_G changes
    always @(pattern_G) begin
        if (pattern_G !== prev_pattern_G) begin
            $fwrite(file_G, "%0d,%0t,%h,%b\n", change_count_G, $time, pattern_G, pattern_G);
            prev_pattern_G = pattern_G;
            change_count_G = change_count_G + 1;
        end
    end
    
    // Monitor pattern_B changes
    always @(pattern_B) begin
        if (pattern_B !== prev_pattern_B) begin
            $fwrite(file_B, "%0d,%0t,%h,%b\n", change_count_B, $time, pattern_B, pattern_B);
            prev_pattern_B = pattern_B;
            change_count_B = change_count_B + 1;
        end
    end
    
endmodule