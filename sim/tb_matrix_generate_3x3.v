`timescale 1ns/100ps
`define clock_period 10
module tb_matrix_generate_3x3();

reg 		clk;               	
reg 		rst_n;              
reg         gray_wr_en;
reg  [7:0]	gray_in;            

wire 	 	matrix_frame_wr_en; 
wire [7:0]	matrix_p11;         
wire [7:0]	matrix_p12;         
wire [7:0]	matrix_p13;         
wire [7:0]	matrix_p21;         
wire [7:0]	matrix_p22;         
wire [7:0]	matrix_p23;         
wire [7:0]	matrix_p31;         
wire [7:0]	matrix_p32;         
wire [7:0]	matrix_p33;  
       
//initialize
initial begin
    clk<=1'b0;
    rst_n<=1'b0;
	gray_wr_en <= 1'b0;
	gray_in <= 8'b0;
    #100;
    rst_n<=1'b1;
	repeat(640) begin //重复执行30次。1个周期高电平，5个周期低电平。
		gray_wr_en <= 1'b1;
		gray_in <= gray_in+1'b1;
		#(`clock_period);
		gray_wr_en <= 1'b0;
		#(`clock_period);	
	end
	#100;
	repeat(640) begin //重复执行30次。1个周期高电平，5个周期低电平。
		gray_wr_en <= 1'b1;
		gray_in <= gray_in+1'b1;
		#(`clock_period);
		gray_wr_en <= 1'b0;
		#(`clock_period);	
	end
		#100;
	repeat(640) begin //重复执行30次。1个周期高电平，5个周期低电平。
		gray_wr_en <= 1'b1;
		gray_in <= gray_in+1'b1;
		#(`clock_period);
		gray_wr_en <= 1'b0;
		#(`clock_period);	
	end
	
end

//50MHz
always #(`clock_period/2) clk<=~clk;


// endmodule
matrix_generate_3x3 matrix_generate_3x3_inst
(
	.clk               	 (clk),
    .rst_n               (rst_n),

    .gray_wr_en          (gray_wr_en),
    .gray_in             (gray_in),

    .matrix_frame_wr_en  (matrix_frame_wr_en),
    .matrix_p11          (matrix_p11),
    .matrix_p12          (matrix_p12),
    .matrix_p13          (matrix_p13),
    .matrix_p21          (matrix_p21),
    .matrix_p22          (matrix_p22),
    .matrix_p23          (matrix_p23),
    .matrix_p31          (matrix_p31),
    .matrix_p32          (matrix_p32),
    .matrix_p33          (matrix_p33)
);

endmodule 