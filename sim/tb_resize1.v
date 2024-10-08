`timescale  1ns/1ns
module tb_resize;

localparam src_image_width  = 640;
localparam src_image_height = 480;
localparam dst_image_width  = 1024;
localparam dst_image_height = 768;
localparam x_ratio          = 40960;    //  floor(src_image_width/dst_image_width*2^16)
localparam y_ratio          = 40960;    //  floor(src_image_height/dst_image_height*2^16)

//----------------------------------------------------------------------
//  clk & rst_n
reg                             clk_in1;
reg                             clk_in2;
reg                             rst_n;

initial
begin
    clk_in1 = 1'b0;
    forever #15 clk_in1 = ~clk_in1;
end

initial
begin
    clk_in2 = 1'b0;
    forever #5 clk_in2 = ~clk_in2;
end

initial
begin
    rst_n = 1'b0;
    repeat(50) @(posedge clk_in1);
    rst_n = 1'b1;
end


//----------------------------------------------------------------------
//  Image data prepred to be processed
reg                             per_img_vsync;
reg                             per_img_href;
reg             [7:0]           per_img_gray;

//  Image data has been processed
wire                            post_img_vsync;
wire                            post_img_href;
wire            [7:0]           post_img_gray;



//parameter define
parameter   H_VALID   =   10'd640 ,   //����Ч����
            H_TOTAL   =   10'd784 ;   //��ɨ������
parameter   V_SYNC    =   10'd4   ,   //��ͬ��
            V_BACK    =   10'd18  ,   //��ʱ�����
            V_VALID   =   10'd480 ,   //����Ч����
            V_FRONT   =   10'd8   ,   //��ʱ��ǰ��
            V_TOTAL   =   10'd510 ;   //��ɨ������

//wire  define
wire            dvp_href     ;   //��ͬ���ź�
wire            dvp_vsync    ;   //��ͬ���ź�


//reg   define
reg             sys_clk         ;   //ģ��dvpʱ���ź�
reg             clk         ;   //ģ��ʱ���ź�
reg             sys_rst_n       ;   //ģ�⸴λ�ź�
reg     [7:0]   dvp_data     ;   //ģ������ͷ�ɼ�ͼ������
reg     [11:0]  cnt_h           ;   //��ͬ��������
reg     [9:0]   cnt_v           ;   //��ͬ��������


reg [7:0]cnt_go;//��¼Ŀǰ�����˶��ٴ�
//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//

//cnt_h:��ͬ���źż�����
always@(posedge clk_in1 or  negedge rst_n)
    if(rst_n == 1'b0)
        cnt_h   <=  12'd0   ;
    else    if(cnt_h == ((H_TOTAL * 3) - 1'b1))
        cnt_h   <=  12'd0   ;
    else
        cnt_h   <=  cnt_h + 1'd1   ;

//dvp_href:��ͬ���ź�
assign  dvp_href = (((cnt_h >= 0)
                      && (cnt_h <= ((H_VALID * 3) - 1'b1)))
                      && ((cnt_v >= (V_SYNC + V_BACK))
                      && (cnt_v <= (V_SYNC + V_BACK + V_VALID - 1'b1))))
                      ? 1'b1 : 1'b0  ;

//cnt_v:��ͬ���źż�����
always@(posedge clk_in1 or  negedge rst_n)
    if(rst_n == 1'b0)
        cnt_v   <=  10'd0 ;
    else    if((cnt_v == (V_TOTAL - 1'b1))
                && (cnt_h == ((H_TOTAL * 3) - 1'b1)))
        cnt_v   <=  10'd0 ;
    else    if(cnt_h == ((H_TOTAL * 3) - 1'b1))
        cnt_v   <=  cnt_v + 1'd1 ;
    else
        cnt_v   <=  cnt_v ;

//vsync:��ͬ���ź�
assign  dvp_vsync = (cnt_v  <= (V_SYNC - 1'b1)) ? 1'b1 : 1'b0  ;

//dvp_data:ģ������ͷ�ɼ�ͼ������
always@(posedge clk_in1 or  negedge rst_n)
    if(rst_n == 1'b0)
        dvp_data <=  8'd0;
    else    if(dvp_href == 1'b1) 
        dvp_data <=  dvp_data + 1'b1;
    else
        dvp_data <=  8'd0+cnt_go;

//----------------------------------------------------------------------
bilinear_interpolation
#(
    .C_SRC_IMG_WIDTH (src_image_width ),
    .C_SRC_IMG_HEIGHT(src_image_height),
    .C_DST_IMG_WIDTH (dst_image_width ),
    .C_DST_IMG_HEIGHT(dst_image_height),
    .C_X_RATIO       (x_ratio         ),        //  floor(C_SRC_IMG_WIDTH/C_DST_IMG_WIDTH*2^16)
    .C_Y_RATIO       (y_ratio         )         //  floor(C_SRC_IMG_HEIGHT/C_DST_IMG_HEIGHT*2^16)
)
u_bilinear_interpolation
(
    .clk_in1        (clk_in1        ),
    .clk_in2        (clk_in2        ),
    .rst_n          (rst_n          ),
    
    //  Image data prepared to be processed
    .per_img_vsync  (dvp_vsync  ),          //  Prepared Image data vsync valid signal
    .per_img_href   (dvp_href   ),          //  Prepared Image data href vaild  signal
    .per_img_gray   (dvp_data   ),          //  Prepared Image brightness input
    
    //  Image data has been processed
    .post_img_vsync (post_img_vsync ),          //  processed Image data vsync valid signal
    .post_img_href  (post_img_href  ),          //  processed Image data href vaild  signal
    .post_img_gray  (post_img_gray  )           //  processed Image brightness output
);


endmodule