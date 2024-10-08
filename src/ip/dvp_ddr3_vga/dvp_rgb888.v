module  dvp_rgb888
#(
//����
	parameter USER_DATA_WIDTH = 128		//����λ��32
)
(
    input   wire            sys_rst_n       ,   //��λ�ź�
// dvpʱ��
    input   wire            dvp_pclk     ,   //����ͷ����ʱ��
    input   wire            dvp_href     ,   //����ͷ��ͬ���ź�
    input   wire            dvp_vsync    ,   //����ͷ��ͬ���ź�
    input   wire    [ 7:0]  dvp_data     ,   //����ͷͼ������
// дFIFO
    output  wire            rgb888_wr_en    ,   //ͼ��������Чʹ���ź�
    output  wire    [USER_DATA_WIDTH-1:0]  rgb888_data_out ,   //ͼ������
// ��ͬ����ʼ�볡ͬ��������־
    output  wire            cmos_vsync_begin,   //��ͬ����ʼ
    output  wire            cmos_vsync_end     //��ͬ������
);
parameter register_cnt = (USER_DATA_WIDTH-8)/8;	//����λ��Ĵ漸��
parameter register_width = USER_DATA_WIDTH-8;	//����λ��

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//reg����
reg                            dvp_vsync_dly;  //����ͷ���볡ͬ���źŴ���
reg     [register_width-1:0]   pic_data_reg;   //����24λͼ�����ݻ���Ĵ�
reg     [USER_DATA_WIDTH-1:0]  data_out_reg;   //���32λͼ�����ݻ���
wire                           data_flag;      //ͼ������ƴ�ӱ�־�ź�
reg                            data_flag_dly1; //ͼ������ƴ�ӱ�־�źŴ���
reg                            data_flag_dly2; //ͼ������ƴ�ӱ�־�źŴ���
reg	    [4:0]                  cnt1;            //����ʱ�������ش���
wire	                       div_three;       //����Ƶ
//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//

//ʹ��PLL
div_three_pll_0002 div_three_pll_inst (
	.refclk   (dvp_pclk),   //  refclk.clk
	.rst      (~sys_rst_n),      //   reset.reset�ߵ�ƽ��λ
	.outclk_0 (div_three), // outclk0.clk
);

//dvp_vsync_dly:����ͷ���볡ͬ���źŴ���,���ڲ���cmos_vsync_begin
always@(posedge dvp_pclk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        dvp_vsync_dly    <=  1'b0;
    else
        dvp_vsync_dly    <=  dvp_vsync;

//cmos_vsync_begin:֡ͼ���־�ź�,ÿ����һ��,����ͬ���źŸߵ�ƽ��ʼ
//cmos_vsync_end:֡ͼ���־�ź�,ÿ����һ��,����ͬ���źŵ͵�ƽ��ʼ
assign  cmos_vsync_begin = ((dvp_vsync_dly == 1'b0)&& (dvp_vsync == 1'b1)) ? 1'b1 : 1'b0;
assign  cmos_vsync_end = ((dvp_vsync_dly == 1'b1)&& (dvp_vsync == 1'b0)) ? 1'b1 : 1'b0;

//����data_flag�ź�
always@(posedge div_three or negedge sys_rst_n)
	if(!sys_rst_n)
		cnt1 <= 5'b0;
	else if(cnt1==register_cnt)
		cnt1 <= 5'b0;
	else if(dvp_href == 1'b1)
		cnt1 <= cnt1+1'b1;
	else 
		cnt1 <= cnt1;
		
assign	data_flag=(dvp_href == 1'b1&&cnt1==register_cnt)?1'b1:1'b0;

//dvp_data��ǰ����Ǵ�ˣ�����С��
//data_out_reg,pic_data_reg,data_flag:���24λͼ�����ݻ���
//����8λͼ�����ݻ�������8λ,ͼ�����ݻ���
always@(posedge div_three or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            pic_data_reg    <=  0;
            data_out_reg    <=  0;
        end
    else    if(dvp_href == 1'b1)
        begin
            pic_data_reg    <=  {dvp_data,pic_data_reg[register_width-1:8]};
            if(data_flag == 1'b1)
                data_out_reg    <=  {dvp_data,pic_data_reg};
            else
                data_out_reg    <=  data_out_reg;
        end
    else
        begin
            pic_data_reg    <=  0;
            data_out_reg    <=  data_out_reg;
        end		
		
//data_flag_dly1:����Ƶͼ�����ݻ������
always@(posedge div_three or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        data_flag_dly1  <=  1'b0;
    else
        data_flag_dly1  <=  data_flag;		
//data_flag_dly2:dvp_pclkͼ�����ݻ������
always@(posedge dvp_pclk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        data_flag_dly2  <=  1'b0;
    else
        data_flag_dly2  <=  data_flag;	


//rgb888_wr_en:���24λͼ������ʹ��
assign  rgb888_wr_en = data_flag_dly1&data_flag_dly2;

//rgb888_data_out:���24λͼ������
assign  rgb888_data_out = data_out_reg;
		
endmodule
