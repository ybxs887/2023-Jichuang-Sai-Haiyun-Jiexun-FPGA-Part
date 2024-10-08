`timescale  1ns/1ns
////////////////////////////////////////////////////////////////////////
// Author        : EmbedFire
// Create Date   : 2019/09/25
// Module Name   : tb_ov7725_top
// Project Name  : ov7725_vga_640x480
// Target Devices: Altera EP4CE10F17C8N
// Tool Versions : Quartus 13.0
// Description   : OV7725����ͷ����ģ������ļ�
// 
// Revision      : V1.0
// Additional Comments:
// 
// ʵ��ƽ̨: Ұ��_��;Pro_FPGA������
// ��˾    : http://www.embedfire.com
// ��̳    : http://www.firebbs.cn
// �Ա�    : https://fire-stm32.taobao.com
////////////////////////////////////////////////////////////////////////

module  tb_ov5640_top();

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define
parameter   H_VALID   =   10'd640 ,   //����Ч����
            H_TOTAL   =   10'd784 ;   //��ɨ������
parameter   V_SYNC    =   10'd4   ,   //��ͬ��
            V_BACK    =   10'd18  ,   //��ʱ�����
            V_VALID   =   10'd480 ,   //����Ч����
            V_FRONT   =   10'd8   ,   //��ʱ��ǰ��
            V_TOTAL   =   10'd510 ;   //��ɨ������

//wire  define
wire            ov7725_href     ;   //��ͬ���ź�
wire            ov7725_vsync    ;   //��ͬ���ź�
wire            cfg_done        ;   //�Ĵ����������
wire            sccb_scl        ;   //SCL
wire            sccb_sda        ;   //SDA
wire            wr_en           ;   //ͼ��������Чʹ���ź�
wire    [15:0]  wr_data         ;   //ͼ������
wire            ov7725_rst_n    ;   //ģ��ov7725��λ�ź�

//reg   define
reg             sys_clk         ;   //ģ��ʱ���ź�
reg             sys_rst_n       ;   //ģ�⸴λ�ź�
reg             ov7725_pclk     ;   //ģ������ͷʱ���ź�
reg     [7:0]   ov7725_data     ;   //ģ������ͷ�ɼ�ͼ������
reg     [11:0]  cnt_h           ;   //��ͬ��������
reg     [9:0]   cnt_v           ;   //��ͬ��������

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//
//ʱ�ӡ���λ�ź�
initial
  begin
    sys_clk     =   1'b1    ;
    ov7725_pclk =   1'b1    ;
    sys_rst_n   <=  1'b0    ;
    #200
    sys_rst_n   <=  1'b1    ;
  end

always  #20 sys_clk = ~sys_clk;
always  #20 ov7725_pclk = ~ov7725_pclk;

assign  ov7725_rst_n = sys_rst_n && cfg_done;

//cnt_h:��ͬ���źż�����
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_h   <=  12'd0   ;
    else    if(cnt_h == ((H_TOTAL * 2) - 1'b1))
        cnt_h   <=  12'd0   ;
    else
        cnt_h   <=  cnt_h + 1'd1   ;

//ov7725_href:��ͬ���ź�
assign  ov7725_href = (((cnt_h >= 0)
                      && (cnt_h <= ((H_VALID * 2) - 1'b1)))
                      && ((cnt_v >= (V_SYNC + V_BACK))
                      && (cnt_v <= (V_SYNC + V_BACK + V_VALID - 1'b1))))
                      ? 1'b1 : 1'b0  ;

//cnt_v:��ͬ���źż�����
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_v   <=  10'd0 ;
    else    if((cnt_v == (V_TOTAL - 1'b1))
                && (cnt_h == ((H_TOTAL * 2) - 1'b1)))
        cnt_v   <=  10'd0 ;
    else    if(cnt_h == ((H_TOTAL * 2) - 1'b1))
        cnt_v   <=  cnt_v + 1'd1 ;
    else
        cnt_v   <=  cnt_v ;

//vsync:��ͬ���ź�
assign  ov7725_vsync = (cnt_v  <= (V_SYNC - 1'b1)) ? 1'b1 : 1'b0  ;

//ov7725_data:ģ������ͷ�ɼ�ͼ������
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        ov7725_data <=  8'd0;
    else    if(ov7725_href == 1'b1)
        ov7725_data <=  ov7725_data + 1'b1;
    else
        ov7725_data <=  8'd0;

//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//
//------------- ov7725_top_inst -------------
ov5640_top  ov5640_top_inst(

    .sys_clk         (sys_clk       ),   //ϵͳʱ��
    .sys_rst_n       (sys_rst_n     ),   //��λ�ź�
    .sys_init_done   (ov7725_rst_n  ),   //ϵͳ��ʼ�����(SDRAM + ����ͷ)

    .ov5640_pclk     (ov7725_pclk   ),   //����ͷ����ʱ��
    .ov5640_href     (ov7725_href   ),   //����ͷ��ͬ���ź�
    .ov5640_vsync    (ov7725_vsync  ),   //����ͷ��ͬ���ź�
    .ov5640_data     (ov7725_data   ),   //����ͷͼ������

    .cfg_done        (cfg_done      ),   //�Ĵ����������
    .sccb_scl        (sccb_scl      ),   //SCL
    .sccb_sda        (sccb_sda      ),   //SDA
    .ov5640_wr_en    (wr_en         ),   //ͼ��������Чʹ���ź�
    .ov5640_data_out (wr_data       )    //ͼ������

);

endmodule

