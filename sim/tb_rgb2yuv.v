`timescale  1ns/1ps
module  tb_rgb2yuv();

wire    [7:0]yuv_out;
wire    yuv_wr_en  ;


reg     ov5640_pclk     ;
reg     rgb_wr_en     ;
reg     rst_n   ;
reg     [15:0]rgb_in;

initial
    begin
	rst_n <= 1'b1;
	rgb_in <= 16'b0;
	ov5640_pclk <= 1'b1;
	rgb_wr_en <= 1'b0;
	#40
	rgb_wr_en <= 1'b1;
	rgb_in <= 16'h1234;
	#20
	rgb_wr_en <= 1'b0;
	#20
	rgb_wr_en <= 1'b1;
	rgb_in <= 16'h5678;
	#20
	rgb_wr_en <= 1'b0;
end

always  #10 ov5640_pclk =   ~ov5640_pclk;


rgb2yuv rgb2yuv_inst
(
	.sys_clk      (ov5640_pclk),   //���빤��ʱ��,������ͷ����ʱ��һ��
	.sys_rst_n    (rst_n), //���븴λ�ź�,�͵�ƽ��Ч

	.rgb_wr_en    (rgb_wr_en),  //����������Чʹ���ź�
	.rgb_in       (rgb_in),//����RGB

	.yuv_wr_en    (yuv_wr_en),  //���������Чʹ���ź�
	.y_out      (yuv_out) //���YUV
);

endmodule