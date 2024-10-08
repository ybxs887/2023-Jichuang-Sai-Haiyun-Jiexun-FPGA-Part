`timescale 1ns/1ns
`define PERIOD_CLK 20
module tb_bin2bcd;

    reg clk, rst_n;
    reg start;
    reg [15:0] bin;
    wire ready, done_tick;
    wire [3:0] bcd4,bcd3, bcd2, bcd1, bcd0;
    integer i;

    bin2bcd u1_bin2bcd
    (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .bin(bin),
        .ready(ready),
        .done_tick(done_tick),
        .bcd4(bcd4),
        .bcd3(bcd3),
        .bcd2(bcd2),
        .bcd1(bcd1),
        .bcd0(bcd0)
    );
    
    initial clk = 1'b1;
    always #(`PERIOD_CLK/2) clk = ~clk;
 
    initial
    begin
        rst_n = 1'b0;
        start = 1'b0;
        bin = 16'd0;
        #(`PERIOD_CLK*200+1)
        rst_n = 1'b1;
        #2000;
        
        for(i=0; i<15000; i=i+1)
            begin
                bin = i;
                start = 1'b1;
                #`PERIOD_CLK;
                start = 1'b0;
                #2000;
            end
        #2000
        $stop; 
    end

endmodule