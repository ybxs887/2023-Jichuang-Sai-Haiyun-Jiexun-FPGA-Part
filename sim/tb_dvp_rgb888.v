`timescale  1ns/1ns
module  tb_dvp_rgb888();

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
//ʱ�ӡ���λ�ź�
initial
  begin
    sys_clk     =   1'b1  ;
    clk     =   1'b1  ;
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
        dvp_data <=  8'd0+cnt_go;

//********************************************************************//
//*************************** Instantiation **************************//
//********************************************************************//
parameter USER_DATA_WIDTH = 128;		//����λ��32
wire            rgb888_wr_en    ;   //��Чͼ��ʹ���ź�
wire    [USER_DATA_WIDTH-1:0]  rgb888_data_out ;   //��Чͼ������
wire            cmos_vsync_begin    ;   //��Чͼ��ʹ���ź�
wire            cmos_vsync_end ;   //��Чͼ������
dvp_rgb888 #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH)
)
dvp_rgb888_inst(
    .sys_rst_n       (sys_rst_n      ),  //��λ�ź�
    .dvp_pclk        (sys_clk        ),  //����ͷ����ʱ��
    .dvp_href        (dvp_href    ),  //����ͷ��ͬ���ź�
    .dvp_vsync       (dvp_vsync   ),  //����ͷ��ͬ���ź�
    .dvp_data        (dvp_data    ),  //����ͷͼ������

    .rgb888_wr_en       (rgb888_wr_en   ),  //ͼ��������Чʹ���ź�
    .rgb888_data_out    (rgb888_data_out),   //ͼ������

    .cmos_vsync_begin   (cmos_vsync_begin   ),    //��ͬ����ʼ
    .cmos_vsync_end     (cmos_vsync_end   )    //��ͬ������
);

//ddr3_write
wire [31:0] ddr3_write_0_control_control_write_base;     //           ddr3_write_0_control.control_write_base
wire [31:0] ddr3_write_0_control_control_write_length;   //                               .control_write_length
wire        ddr3_write_0_control_control_done;           //                               .control_done
wire        ddr3_write_0_control_control_fixed_location; //                               .control_fixed_location
wire        ddr3_write_0_control_control_go;             //                               .control_go

wire        ddr3_write_0_soft_reset_beginbursttransfer;  //        ddr3_write_0_soft_reset.beginbursttransfer
wire        ddr3_write_0_user_user_write_clk;            //              ddr3_write_0_user.user_write_clk
wire        ddr3_write_0_user_user_write_buffer;         //                               .user_write_buffer
wire [USER_DATA_WIDTH-1:0] ddr3_write_0_user_user_buffer_data;          //                               .user_buffer_data
wire        ddr3_write_0_user_user_buffer_full;          //                               .user_buffer_full

wire          ddr3_write_0_avalon_master_waitrequest;                         // mm_interconnect_0:ddr3_write_0_avalon_master_waitrequest -> ddr3_write_0:master_waitrequest
wire   [31:0] ddr3_write_0_avalon_master_address;                             // ddr3_write_0:master_address -> mm_interconnect_0:ddr3_write_0_avalon_master_address
wire    [3:0] ddr3_write_0_avalon_master_byteenable;                          // ddr3_write_0:master_byteenable -> mm_interconnect_0:ddr3_write_0_avalon_master_byteenable
wire          ddr3_write_0_avalon_master_write;                               // ddr3_write_0:master_write -> mm_interconnect_0:ddr3_write_0_avalon_master_write
wire   [USER_DATA_WIDTH-1:0] ddr3_write_0_avalon_master_writedata;                           // ddr3_write_0:master_writedata -> mm_interconnect_0:ddr3_write_0_avalon_master_writedata
wire    [4:0] ddr3_write_0_avalon_master_burstcount;                          // ddr3_write_0:master_burstcount -> mm_interconnect_0:ddr3_write_0_avalon_master_burstcount


//���Զ�д����
parameter MAXFRAME= 8'd1;//��д1֡
//֡�����־
reg start_cap;	//��ʼ��׽һ֡�źţ���hps���𣬸ߵ�ƽ��Ч��������һ֡����λ0
reg en_cap;		//������׽һ֡�źţ�start_cap��Чʱ����ͬ���ߵ�ƽ����ʱ��ʼ��Ч
reg control_go;//�����ź�
reg [7:0]frame_count;//֡�����������ڿ��ƶ�д����֡
reg hps_start_cap;  //hps�����Ŀ�ʼ��׽�ߵ�ƽ��ֻ��һ��ʱ�����ڣ�����ʱ��Ϊ�͵�ƽ
reg hps_start_cap1;  //hps�����Ŀ�ʼ��׽�ߵ�ƽ��ֻ��һ��ʱ�����ڣ�����ʱ��Ϊ�͵�ƽ
reg status_register;  //hps�����Ŀ�ʼ��׽�ߵ�ƽ��ֻ��һ��ʱ�����ڣ�����ʱ��Ϊ�͵�ƽ

//��������ź�������
reg [1:0]D;
wire pos_edge;
//���done�ź�������
reg flag;
reg [1:0]D1;
wire done_pos_edge;
//1 hps���ƶ�д
initial
    begin
    hps_start_cap1   <=  1'b0  ;
    #35000000
    hps_start_cap1   <=  1'b1  ;
    #35000000
    hps_start_cap1   <=  1'b0  ;
    #60000000
    hps_start_cap1   <=  1'b1  ;
    #35001000
    hps_start_cap1   <=  1'b0  ;
    #25416566
    hps_start_cap1   <=  1'b1  ;
    end

//start_cap	
always @(posedge sys_clk or negedge sys_rst_n)
	if (sys_rst_n == 1'b0)
		start_cap  <= 1'd0;
	else if(hps_start_cap)
		start_cap <= 1'd1;
	else if(en_cap && cmos_vsync_begin) 
    begin
		start_cap  <= 1'd0;
    end
	else
		start_cap  <= start_cap;
		
//en_cap
always @(posedge sys_clk or negedge sys_rst_n)
	if (sys_rst_n == 1'b0)
		en_cap  <= 1'd0;
	else if (start_cap)begin
		if(cmos_vsync_end)
			en_cap  <= 1'd1;
		else if(cmos_vsync_begin)
			en_cap  <= 1'd0;
	end
	else
		en_cap  <= 1'd0;
		
//����control_go�ź�
always @(posedge sys_clk or negedge sys_rst_n)
	if (sys_rst_n == 1'b0)
		control_go  <= 1'd0;
	else if (start_cap)begin
		if(cmos_vsync_end)
			control_go  <= 1'd1;
		else
			control_go  <= 1'd0;
	end
	else
		control_go  <= 1'd0;
assign ddr3_write_0_control_control_go=control_go;

//��ȡ֡������
always @(posedge sys_clk or negedge sys_rst_n)
	if (sys_rst_n == 1'b0) begin
		frame_count  <= 8'd0;
    end  
	else if(frame_count== MAXFRAME) begin//����Ѿ����һ��
		frame_count  <= 8'd0;
    end
	else if(control_go== 1'b1)
		frame_count <= frame_count + 1'b1;
    else
		frame_count  <= frame_count;

//���ﵽһ�α�־�źŵ���������
always @(posedge clk)
    if(hps_start_cap==0 && pos_edge==1 ) begin
        hps_start_cap <= 1;
    end
	else if ((frame_count!=MAXFRAME)) begin
        hps_start_cap <= hps_start_cap;
    end 
    else begin
		hps_start_cap  <= 1'b0; 
    end

//ʹ�ñ��ؼ���������ź������أ�ֻ�����һ��ʱ������
always @(posedge clk or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)begin
        D <= 2'b00;
    end
    else begin
        D <= {D[0], hps_start_cap1};  	//D[1]��ʾǰһ״̬��D[0]��ʾ��һ״̬�������ݣ� 
    end
    end
assign  pos_edge = ~D[1] & D[0];

//���������������ڲ���
always @(posedge pos_edge or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_go <= 1'b0;
    else
        cnt_go <= cnt_go+1'b1;


parameter   LENGTH   =   32'h0012c000;        //buffer1
parameter   buffer0   =   32'h10345688 ;   //buffer0
parameter   buffer1   =   buffer0+LENGTH;        //buffer1
assign ddr3_write_0_control_control_write_length=LENGTH;//����

assign ddr3_write_0_avalon_master_waitrequest=1'b0;//master_waitrequestһֱ���ͣ������õȴ������޷�����ͻ������
assign ddr3_write_0_soft_reset_beginbursttransfer=1'b0;//��⵽�����ظ�λ

assign ddr3_write_0_user_user_write_clk=sys_clk;//дʱ��
assign ddr3_write_0_user_user_write_buffer=rgb888_wr_en&en_cap;//д����
assign ddr3_write_0_user_user_buffer_data=rgb888_data_out;//����


//����ddr3_write���з���
ddr3_write #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH),
    .AVALON_DATA_WIDTH   (USER_DATA_WIDTH),
    .MEMORY_BASED_FIFO   (1),
    .FIFO_DEPTH          (256),
    .FIFO_DEPTH_LOG2     (8),
    .ADDRESS_WIDTH       (32),
    .BURST_CAPABLE       (1),
    .MAXIMUM_BURST_COUNT (16),
    .BURST_COUNT_WIDTH   (5)
) ddr3_write_0 (
    .clk                    (clk),                                       //         clock.clk
    .reset_n                (sys_rst_n),                                //�͵�ƽ��λ         
    .soft_reset             (ddr3_write_0_soft_reset_beginbursttransfer),   //�ߵ�ƽ��Ч

    .control_write_base     (ddr3_write_0_control_control_write_base),     //       control.control_write_base
    .control_write_length   (ddr3_write_0_control_control_write_length),   //              .control_write_length
    .control_done           (ddr3_write_0_control_control_done),           //              .control_done
    .control_fixed_location (), //              .control_fixed_location
    .control_go             (ddr3_write_0_control_control_go),             //              .control_go

    .user_write_clk         (ddr3_write_0_user_user_write_clk),            //dvpʱ��
    .user_write_buffer      (ddr3_write_0_user_user_write_buffer),         //              .user_write_buffer
    .user_buffer_data       (ddr3_write_0_user_user_buffer_data),          //              .user_buffer_data
    .user_buffer_full       (),          //              .user_buffer_full
    
    .master_address         (ddr3_write_0_avalon_master_address),          // avalon_master.address
    .master_write           (ddr3_write_0_avalon_master_write),            //              .write
    .master_byteenable      (ddr3_write_0_avalon_master_byteenable),       //              .byteenable
    .master_writedata       (ddr3_write_0_avalon_master_writedata),        //              .writedata
    .master_burstcount      (ddr3_write_0_avalon_master_burstcount),       //              .burstcount
    .master_waitrequest     (ddr3_write_0_avalon_master_waitrequest)      //              .waitrequest
);

//
//˫buffer��д/ƹ�Ҳ���
//
//ʹ�ñ��ؼ����һ֡д���control_done�źţ���һ��������ȡ��һ��


always @(posedge ddr3_write_0_control_control_done or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)begin
        flag <= 1'b0;
    end
    else begin
        flag <= ~flag;
    end
end

//ʹ�ñ��ؼ����done�ź������أ�ֻ�����һ��ʱ������
always @(posedge clk or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)begin
        D1 <= 2'b00;
    end
    else begin
        D1 <= {D1[0], ddr3_write_0_control_control_done};  	//D[1]��ʾǰһ״̬��D[0]��ʾ��һ״̬�������ݣ� 
    end
    end
assign  done_pos_edge = ~D1[1] & D1[0];

//�����Ĵ��俪ʼ�����״̬��־	
always @(posedge clk or posedge sys_rst_n)
	if (sys_rst_n == 1'b0)
		status_register  <= 1'd0;
	else if(pos_edge)
		status_register  <= 1'd0;
	else if(done_pos_edge)
		status_register  <= 1'd1;
//control_done�źŲ�����
//ʹ������߼���ֵ������ʹ�ܺ����ݵ�ַ���ܶ�Ӧ
assign ddr3_write_0_control_control_write_base = (flag == 1'b1) ? buffer0: buffer1; //��ַ



endmodule

