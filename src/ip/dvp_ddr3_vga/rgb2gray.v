module  rgb2gray
(
    input   wire            sys_rst_n       ,   //��λ�ź�
// ����dvpʱ��
    input   wire            dvp_pclk_in     ,   //��������ͷ����ʱ��
    input   wire            dvp_href_in     ,   //��������ͷ��ͬ���ź�
    input   wire            dvp_vsync_in    ,   //��������ͷ��ͬ���ź�
    input   wire    [ 7:0]  dvp_data_in     ,   //��������ͷͼ������
// ���dvpʱ��
    output   wire            dvp_pclk_out     ,   //�������ͷ����ʱ��
    output   wire            dvp_href_out     ,   //�������ͷ��ͬ���ź�
    output   wire            dvp_vsync_out    ,   //�������ͷ��ͬ���ź�
    output   wire    [ 7:0]  dvp_data_out        //�������ͷͼ������
);

//����Ƶ/�ϰ���ʹ��PLL�滻
// reg   [1:0]  cnt; 
// reg       div_clk1;
// reg       div_clk2;
// wire	                       div_three;       //����Ƶ
// always @(posedge dvp_pclk_in or negedge sys_rst_n)begin
  // if(sys_rst_n == 1'b0)begin
    // cnt <= 0;
  // end
  // else if(cnt == 2)
    // cnt <= 0;
  // else begin
    // cnt <= cnt + 1;
  // end
// end
// always @(posedge dvp_pclk_in or negedge sys_rst_n)begin
  // if(sys_rst_n == 1'b0)begin
    // div_clk1 <= 0;
  // end
  // else if(cnt == 0)begin
    // div_clk1 <= ~div_clk1;
  // end
  // else
    // div_clk1 <= div_clk1;
// end
// always @(negedge dvp_pclk_in or negedge sys_rst_n)begin
  // if(sys_rst_n == 1'b0)begin
    // div_clk2 <= 0;
  // end
  // else if(cnt == 2)begin
    // div_clk2 <= ~div_clk2;
  // end
  // else
    // div_clk2 <= div_clk2;
// end
// assign  div_three = div_clk2 ^ div_clk1;

//ʹ��PLL
div_three_pll_0002 div_three_pll_inst (
	.refclk   (dvp_pclk_in),   //  refclk.clk
	.rst      (~sys_rst_n),      //   reset.reset�ߵ�ƽ��λ
	.outclk_0 (div_three), // outclk0.clk
);


//����Ƶ����
reg   [ 7:0]    dvp_data_out_reg;
always@(posedge div_three or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
		  dvp_data_out_reg <= 8'd0;
    else    if(dvp_href_in == 1'b1)
      dvp_data_out_reg    <=  dvp_data_in ;
    else
      dvp_data_out_reg    <=  dvp_data_out_reg;


assign dvp_data_out=dvp_data_out_reg;
assign dvp_pclk_out=div_three;
assign dvp_href_out=dvp_href_in;
assign dvp_vsync_out=dvp_vsync_in;	


//����һ����ͬ�����ж��ٸ�����
reg             [11:0]          out_hs_cnt;              
always @(posedge div_three or negedge sys_rst_n)
begin
    if(sys_rst_n == 1'b0)
        out_hs_cnt<= 12'b0;
    else
    begin
        if((dvp_vsync_out == 1'b0)&&(dvp_href_out == 1'b1))
            out_hs_cnt <= out_hs_cnt + 1'b1;
        else
            out_hs_cnt <= 12'b0;
    end
end

//����һ����ͬ�����ж��ٸ�����
reg             [11:0]          in_hs_cnt;              
always @(posedge dvp_pclk_in or negedge sys_rst_n)
begin
    if(sys_rst_n == 1'b0)
        in_hs_cnt<= 12'b0;
    else
    begin
        if((dvp_vsync_out == 1'b0)&&(dvp_href_out == 1'b1))
            in_hs_cnt <= in_hs_cnt + 1'b1;
        else
            in_hs_cnt <= 12'b0;
    end
end
endmodule	
