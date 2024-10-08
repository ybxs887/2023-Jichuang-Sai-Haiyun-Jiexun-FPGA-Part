`timescale  1ns/1ns
module  tb_resize2;


//----------------------------------------------------------------------
//dvpʱ�����
//parameter define
parameter   H_VALID   =   10'd400 ,   //����Ч����
            H_TOTAL   =   10'd440 ;   //��ɨ������
parameter   V_SYNC    =   10'd20   ,   //��ͬ��
            V_BACK    =   10'd20  ,   //��ʱ�����
            V_VALID   =   10'd320 ,   //����Ч����
            V_FRONT   =   10'd20   ,   //��ʱ��ǰ��
            V_TOTAL   =   10'd380 ;   //��ɨ������

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

//ʱ�ӡ���λ�ź�
initial
  begin
    sys_clk     =   1'b1  ;
    clk         =   1'b1  ;
    sys_rst_n   <=  1'b0  ;
    #200
    sys_rst_n   <=  1'b1  ;
  end

always  #20 sys_clk = ~sys_clk;
always  #5 clk = ~clk;

//cnt_h:��ͬ���źż�����
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
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
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
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
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        dvp_data <=  8'd0;
    else    if(dvp_href == 1'b1) 
        dvp_data <=  dvp_data + 1'b1;
    else
        dvp_data <=  8'd0;

parameter    USER_DATA_WIDTH = 32;		//����λ��32
wire                        resize_wr_en    ;   //ͼ��������Чʹ���ź�
wire [USER_DATA_WIDTH-1:0]  resize_data_out ;   //ͼ������
wire    cmos_vsync_begin;   //��ͬ����ʼ
wire    cmos_vsync_end ;    //��ͬ������
resize_top  #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH)
 )
 resize_top_inst(
    .sys_rst_n        (sys_rst_n      ),  //��λ�ź�

    .dvp_pclk_in        (sys_clk        ),  //����ͷ����ʱ��
    .dvp_href_in        (dvp_href    ),  //����ͷ��ͬ���ź�
    .dvp_vsync_in       (dvp_vsync   ),  //����ͷ��ͬ���ź�
    .dvp_data_in        (dvp_data    ),  //����ͷͼ������

    .resize_wr_en       (resize_wr_en   ),  //ͼ��������Чʹ���ź�
    .resize_data_out    (resize_data_out),   //ͼ������

    .cmos_vsync_begin   (cmos_vsync_begin   ),    //��ͬ����ʼ
    .cmos_vsync_end     (cmos_vsync_end   )    //��ͬ������
);







// //----------------------------------------------------------------------
// //rgb2gray
// wire            dvp_pclk_out    ;   //��Чͼ��ʹ���ź�
// wire            dvp_href_out ;   //��Чͼ������
// wire            dvp_vsync_out    ;   //��Чͼ��ʹ���ź�
// wire     [7:0]  dvp_data_out ;   //��Чͼ������

// rgb2gray rgb2gray_inst(
//     .sys_rst_n       (sys_rst_n      ),  //��λ�ź�

//     .dvp_pclk_in        (sys_clk        ),  //����ͷ����ʱ��
//     .dvp_href_in        (dvp_href    ),  //����ͷ��ͬ���ź�
//     .dvp_vsync_in       (dvp_vsync   ),  //����ͷ��ͬ���ź�
//     .dvp_data_in       (dvp_data    ),  //����ͷͼ������

//     .dvp_pclk_out        (dvp_pclk_out        ),  //����ͷ����ʱ��
//     .dvp_href_out        (dvp_href_out    ),  //����ͷ��ͬ���ź�
//     .dvp_vsync_out       (dvp_vsync_out   ),  //����ͷ��ͬ���ź�
//     .dvp_data_out       (dvp_data_out    )  //����ͷͼ������

// );


// //----------------------------------------------------------------------
// //resize
// localparam src_image_width  = 400;
// localparam src_image_height = 320;
// localparam dst_image_width  = 300;
// localparam dst_image_height = 300;
// localparam x_ratio          = 87381;    //  floor(src_image_width/dst_image_width*2^16)
// localparam y_ratio          = 69905;    //  floor(src_image_height/dst_image_height*2^16)

// //  Image data has been processed
// wire                            post_img_vsync;
// wire                            post_img_href;
// wire            [7:0]           post_img_gray;

// bilinear_interpolation
// #(
//     .C_SRC_IMG_WIDTH (src_image_width ),
//     .C_SRC_IMG_HEIGHT(src_image_height),
//     .C_DST_IMG_WIDTH (dst_image_width ),
//     .C_DST_IMG_HEIGHT(dst_image_height),
//     .C_X_RATIO       (x_ratio         ),        //  floor(C_SRC_IMG_WIDTH/C_DST_IMG_WIDTH*2^16)
//     .C_Y_RATIO       (y_ratio         )         //  floor(C_SRC_IMG_HEIGHT/C_DST_IMG_HEIGHT*2^16)
// )
// u_bilinear_interpolation
// (
//     .clk_in1        (dvp_pclk_out        ),
//     .clk_in2        (dvp_pclk_out        ),
//     .rst_n          (sys_rst_n          ),
    
//     //  Image data prepared to be processed
//     .per_img_vsync1  (dvp_vsync_out  ),          //  Prepared Image data vsync valid signal
//     .per_img_href   (dvp_href_out   ),          //  Prepared Image data href vaild  signal
//     .per_img_gray   (dvp_data_out   ),          //  Prepared Image brightness input
    
//     //  Image data has been processed
//     .post_img_vsync1 (post_img_vsync ),          //  processed Image data vsync valid signal
//     .post_img_href  (post_img_href  ),          //  processed Image data href vaild  signal
//     .post_img_gray  (post_img_gray  )           //  processed Image brightness output
// );

// //----------------------------------------------------------------------
// //dvp_rgb888
// parameter USER_DATA_WIDTH = 32;		//����λ��32
// wire            rgb888_wr_en    ;   //��Чͼ��ʹ���ź�
// wire    [USER_DATA_WIDTH-1:0]  rgb888_data_out ;   //��Чͼ������
// wire            cmos_vsync_begin    ;   //��Чͼ��ʹ���ź�
// wire            cmos_vsync_end ;   //��Чͼ������
// dvp_rgb888 #(
//     .USER_DATA_WIDTH     (USER_DATA_WIDTH)
// )
// dvp_rgb888_inst(
//     .sys_rst_n       (sys_rst_n      ),  //��λ�ź�
//     .dvp_pclk        (dvp_pclk_out     ),  //����ͷ����ʱ��
//     .dvp_href        (post_img_href    ),  //����ͷ��ͬ���ź�
//     .dvp_vsync       (post_img_vsync   ),  //����ͷ��ͬ���ź�
//     .dvp_data        (post_img_gray    ),  //����ͷͼ������

//     .rgb888_wr_en       (rgb888_wr_en   ),  //ͼ��������Чʹ���ź�
//     .rgb888_data_out    (rgb888_data_out),   //ͼ������

//     .cmos_vsync_begin   (cmos_vsync_begin   ),    //��ͬ����ʼ
//     .cmos_vsync_end     (cmos_vsync_end   )    //��ͬ������
// );


endmodule
