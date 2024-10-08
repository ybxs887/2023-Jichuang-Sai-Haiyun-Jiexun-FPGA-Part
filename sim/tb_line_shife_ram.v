module tb_line_shife_ram();

reg clk;
reg rst_n;
reg [7:0] row3_data;
wire [7:0] row2_data;
wire [7:0] row1_data;
reg per_frame_href;
reg clk_enable;


//行同步信号在新一行开头为低电平，数据有效为高电平

//initialize
initial begin
    clk<=1'b0;
	clk_enable<=1'b0;
    rst_n<=1'b0;
	per_frame_href<=1'b0;
    #100;
    rst_n<=1'b1;
	per_frame_href<=1'b1;
end

//50MHz
always #10 clk<=~clk;
always #20 clk_enable<=~clk_enable;

//data add
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        row3_data<=8'd0;
    end
    else row3_data<=row3_data+1'b1;
end


// endmodule
line_shife_ram line_shife_ram_inst
(
    .clock              (clk),
    .clken              (clk_enable),
    .per_frame_href     (per_frame_href),
 
    .shiftin            (row3_data),
    .taps0x             (row2_data),
    .taps1x             (row1_data)
);

endmodule 