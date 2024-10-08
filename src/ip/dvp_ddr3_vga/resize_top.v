module  resize_top
#(
//����
	parameter USER_DATA_WIDTH = 32		//���λ��32
)
(
    input   wire            sys_rst_n       ,   //��λ�ź�
// ����dvpʱ��
    input   wire            dvp_pclk_in     ,   //��������ͷ����ʱ��
    input   wire            dvp_href_in     ,   //��������ͷ��ͬ���ź�
    input   wire            dvp_vsync_in    ,   //��������ͷ��ͬ���ź�
    input   wire    [ 7:0]  dvp_data_in     ,   //��������ͷͼ������
// ���dvpʱ��
	output  wire            resize_pclk,   //��ͬ����ʼ
// дFIFO
    output  wire            resize_wr_en    ,   //ͼ��������Чʹ���ź�
    output  wire    [USER_DATA_WIDTH-1:0]  resize_data_out ,   //ͼ������
// ��ͬ����ʼ�볡ͬ��������־
    output  wire            cmos_vsync_begin,   //��ͬ����ʼ
    output  wire            cmos_vsync_end     //��ͬ������
);


//----------------------------------------------------------------------
//rgb2gray
//----------------------------------------------------------------------

wire            dvp_pclk_out    ;   //��Чͼ��ʹ���ź�
wire            dvp_href_out ;   //��Чͼ������
wire            dvp_vsync_out    ;   //��Чͼ��ʹ���ź�
wire     [7:0]  dvp_data_out ;   //��Чͼ������

rgb2gray rgb2gray_inst(
    .sys_rst_n          (sys_rst_n      ),  //��λ�ź�

    .dvp_pclk_in        (dvp_pclk_in    ),  //����ͷ����ʱ��
    .dvp_href_in        (dvp_href_in    ),  //����ͷ��ͬ���ź�
    .dvp_vsync_in       (dvp_vsync_in   ),  //����ͷ��ͬ���ź�
    .dvp_data_in        (dvp_data_in    ),  //����ͷͼ������

    .dvp_pclk_out        (dvp_pclk_out    ),  //����ͷ����ʱ��
    .dvp_href_out        (dvp_href_out    ),  //����ͷ��ͬ���ź�
    .dvp_vsync_out       (dvp_vsync_out   ),  //����ͷ��ͬ���ź�
    .dvp_data_out        (dvp_data_out    )  //����ͷͼ������

);


//----------------------------------------------------------------------
//resize
//----------------------------------------------------------------------

localparam src_image_width  = 400;
localparam src_image_height = 320;
localparam dst_image_width  = 300;
localparam dst_image_height = 300;
localparam x_ratio          = 87381;    //  floor(src_image_width/dst_image_width*2^16)
localparam y_ratio          = 69905;    //  floor(src_image_height/dst_image_height*2^16)

//  Image data has been processed
wire                            post_img_vsync;
wire                            post_img_href;
wire            [7:0]           post_img_gray;

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
    .clk_in1        (dvp_pclk_out        ),
    .clk_in2        (dvp_pclk_out        ),
    .rst_n          (sys_rst_n          ),
    
    //  Image data prepared to be processed
    .per_img_vsync1 (dvp_vsync_out  ),          //  Prepared Image data vsync valid signal
    .per_img_href   (dvp_href_out   ),          //  Prepared Image data href vaild  signal
    .per_img_gray   (dvp_data_out   ),          //  Prepared Image brightness input
    
    //  Image data has been processed
    .post_img_vsync1 (post_img_vsync ),          //  processed Image data vsync valid signal
    .post_img_href   (post_img_href  ),          //  processed Image data href vaild  signal
    .post_img_gray   (post_img_gray  )           //  processed Image brightness output
);


//----------------------------------------------------------------------
//dvp_gray
//----------------------------------------------------------------------

dvp_gray #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH)
)
dvp_gray_inst(
    .sys_rst_n       (sys_rst_n      ),  //��λ�ź�
    .dvp_pclk        (dvp_pclk_out     ),  //����ͷ����ʱ��
    .dvp_href        (post_img_href    ),  //����ͷ��ͬ���ź�
    .dvp_vsync       (post_img_vsync   ),  //����ͷ��ͬ���ź�
    .dvp_data        (post_img_gray    ),  //����ͷͼ������

    .rgb888_wr_en       (resize_wr_en   ),  //ͼ��������Чʹ���ź�
    .rgb888_data_out    (resize_data_out),   //ͼ������

    .cmos_vsync_begin   (cmos_vsync_begin   ),    //��ͬ����ʼ
    .cmos_vsync_end     (cmos_vsync_end   )    //��ͬ������
);



assign resize_pclk=dvp_pclk_out;

endmodule

