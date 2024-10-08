`timescale 1ns/100ps
`define clock_period 10
module  tb_rgb888();

reg 		clk;               	
reg 		rst_n;      
wire [31:0]	write_user_buffer_input_data;         
wire     	write_user_write_buffer; 

//initialize
initial begin
    clk<=1'b0;
    rst_n<=1'b0;
    #100;
    rst_n<=1'b1;
end

//50MHz
always #(`clock_period/2) clk<=~clk;


rgb888 rgb888_inst
(

	.clk                          (clk),
    .rst_n                        (rst_n),
                                  
    .write_user_buffer_input_data (write_user_buffer_input_data),
    .write_user_write_buffer      (write_user_write_buffer)
);

endmodule
