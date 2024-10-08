`timescale  1ns/1ns
module  tb_dvp_rgb888();

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define
parameter   H_VALID   =   10'd640 ,   //行有效数据
            H_TOTAL   =   10'd784 ;   //行扫描周期
parameter   V_SYNC    =   10'd4   ,   //场同步
            V_BACK    =   10'd18  ,   //场时序后沿
            V_VALID   =   10'd480 ,   //场有效数据
            V_FRONT   =   10'd8   ,   //场时序前沿
            V_TOTAL   =   10'd510 ;   //场扫描周期

//wire  define
wire            dvp_href     ;   //行同步信号
wire            dvp_vsync    ;   //场同步信号
wire            rgb888_wr_en    ;   //有效图像使能信号
wire    [23:0]  rgb888_data_out ;   //有效图像数据
wire            cmos_vsync_begin    ;   //有效图像使能信号
wire            cmos_vsync_end ;   //有效图像数据

//reg   define
reg             sys_clk         ;   //模拟dvp时钟信号
reg             clk         ;   //模拟时钟信号
reg             sys_rst_n       ;   //模拟复位信号
reg     [7:0]   dvp_data     ;   //模拟摄像头采集图像数据
reg     [11:0]  cnt_h           ;   //行同步计数器
reg     [9:0]   cnt_v           ;   //场同步计数器


reg [7:0]cnt_go;//记录目前启动了多少次
//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//
//时钟、复位信号
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

//cnt_h:行同步信号计数器
always@(posedge sys_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_h   <=  12'd0   ;
    else    if(cnt_h == ((H_TOTAL * 3) - 1'b1))
        cnt_h   <=  12'd0   ;
    else
        cnt_h   <=  cnt_h + 1'd1   ;

//dvp_href:行同步信号
assign  dvp_href = (((cnt_h >= 0)
                      && (cnt_h <= ((H_VALID * 3) - 1'b1)))
                      && ((cnt_v >= (V_SYNC + V_BACK))
                      && (cnt_v <= (V_SYNC + V_BACK + V_VALID - 1'b1))))
                      ? 1'b1 : 1'b0  ;

//cnt_v:场同步信号计数器
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

//vsync:场同步信号
assign  dvp_vsync = (cnt_v  <= (V_SYNC - 1'b1)) ? 1'b1 : 1'b0  ;

//dvp_data:模拟摄像头采集图像数据
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
dvp_rgb888 dvp_rgb888_inst
(
    .sys_rst_n       (sys_rst_n      ),  //复位信号
    .dvp_pclk        (sys_clk        ),  //摄像头像素时钟
    .dvp_href        (dvp_href    ),  //摄像头行同步信号
    .dvp_vsync       (dvp_vsync   ),  //摄像头场同步信号
    .dvp_data        (dvp_data    ),  //摄像头图像数据

    .rgb888_wr_en       (rgb888_wr_en   ),  //图像数据有效使能信号
    .rgb888_data_out    (rgb888_data_out),   //图像数据

    .cmos_vsync_begin   (cmos_vsync_begin   ),    //场同步开始
    .cmos_vsync_end     (cmos_vsync_end   )    //场同步结束
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
wire [31:0] ddr3_write_0_user_user_buffer_data;          //                               .user_buffer_data
wire        ddr3_write_0_user_user_buffer_full;          //                               .user_buffer_full

wire          ddr3_write_0_avalon_master_waitrequest;                         // mm_interconnect_0:ddr3_write_0_avalon_master_waitrequest -> ddr3_write_0:master_waitrequest
wire   [31:0] ddr3_write_0_avalon_master_address;                             // ddr3_write_0:master_address -> mm_interconnect_0:ddr3_write_0_avalon_master_address
wire    [3:0] ddr3_write_0_avalon_master_byteenable;                          // ddr3_write_0:master_byteenable -> mm_interconnect_0:ddr3_write_0_avalon_master_byteenable
wire          ddr3_write_0_avalon_master_write;                               // ddr3_write_0:master_write -> mm_interconnect_0:ddr3_write_0_avalon_master_write
wire   [31:0] ddr3_write_0_avalon_master_writedata;                           // ddr3_write_0:master_writedata -> mm_interconnect_0:ddr3_write_0_avalon_master_writedata
wire    [4:0] ddr3_write_0_avalon_master_burstcount;                          // ddr3_write_0:master_burstcount -> mm_interconnect_0:ddr3_write_0_avalon_master_burstcount


//测试读写控制
parameter MAXFRAME= 8'd1;//读写1帧
//帧捕获标志
reg start_cap;	//开始捕捉一帧信号，由hps发起，高电平有效，捕获完一帧后置位0
reg en_cap;		//结束捕捉一帧信号，start_cap有效时，场同步高电平结束时开始有效
reg control_go;//启动信号
reg [7:0]frame_count;//帧计数器，用于控制读写多少帧
reg hps_start_cap;  //hps决定的开始捕捉高电平，只有一个时间周期，其余时间为低电平
reg hps_start_cap1;  //hps决定的开始捕捉高电平，只有一个时间周期，其余时间为低电平

reg status_register;  //hps决定的开始捕捉高电平，只有一个时间周期，其余时间为低电平
//检测启动信号上升沿
reg [1:0]D;
wire pos_edge;
//检测done信号上升沿
reg flag;
reg [1:0]D1;
wire done_pos_edge;
//1 hps控制读写
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
		
//产生control_go信号
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

//读取帧计数器
always @(posedge sys_clk or negedge sys_rst_n)
	if (sys_rst_n == 1'b0) begin
		frame_count  <= 8'd0;
    end  
	else if(frame_count== MAXFRAME) begin//如果已经清空一次
		frame_count  <= 8'd0;
    end
	else if(control_go== 1'b1)
		frame_count <= frame_count + 1'b1;
    else
		frame_count  <= frame_count;

//若达到一次标志信号的启动上限
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

//使用边沿检测检测启动信号上升沿，只会持续一个时钟周期
always @(posedge clk or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)begin
        D <= 2'b00;
    end
    else begin
        D <= {D[0], hps_start_cap1};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
    end
    end
assign  pos_edge = ~D[1] & D[0];

//计数启动次数用于测试
always @(posedge pos_edge or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_go <= 1'b0;
    else
        cnt_go <= cnt_go+1'b1;


parameter   LENGTH   =   32'h0012c000;        //buffer1
parameter   buffer0   =   32'h10345688 ;   //buffer0
parameter   buffer1   =   buffer0+LENGTH;        //buffer1
assign ddr3_write_0_control_control_write_length=LENGTH;//长度
assign ddr3_write_0_user_user_buffer_data={8'b0,rgb888_data_out};//数据
assign ddr3_write_0_avalon_master_waitrequest=1'b0;//master_waitrequest一直拉低，即不用等待否则无法进行突发传输
assign ddr3_write_0_soft_reset_beginbursttransfer=1'b0;//检测到上升沿复位

//例化ddr3_write进行仿真
ddr3_write #(
    .USER_DATA_WIDTH     (32),
    .AVALON_DATA_WIDTH   (32),
    .MEMORY_BASED_FIFO   (1),
    .FIFO_DEPTH          (256),
    .FIFO_DEPTH_LOG2     (8),
    .ADDRESS_WIDTH       (32),
    .BURST_CAPABLE       (1),
    .MAXIMUM_BURST_COUNT (16),
    .BURST_COUNT_WIDTH   (5)
) ddr3_write_0 (
    .clk                    (clk),                                       //         clock.clk
    .reset_n                (sys_rst_n),                                //低电平复位         
    .soft_reset             (ddr3_write_0_soft_reset_beginbursttransfer),   //高电平有效

    .control_write_base     (ddr3_write_0_control_control_write_base),     //       control.control_write_base
    .control_write_length   (ddr3_write_0_control_control_write_length),   //              .control_write_length
    .control_done           (ddr3_write_0_control_control_done),           //              .control_done
    .control_fixed_location (), //              .control_fixed_location
    .control_go             (ddr3_write_0_control_control_go),             //              .control_go

    .user_write_clk         (sys_clk),            //dvp时钟
    .user_write_buffer      (rgb888_wr_en&en_cap),         //              .user_write_buffer
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
//双buffer读写/乒乓操作
//
//使用边沿检测检测一帧写完的control_done信号，来一次上升沿取反一次


always @(posedge ddr3_write_0_control_control_done or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)begin
        flag <= 1'b0;
    end
    else begin
        flag <= ~flag;
    end
end

//使用边沿检测检测done信号上升沿，只会持续一个时钟周期
always @(posedge clk or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)begin
        D1 <= 2'b00;
    end
    else begin
        D1 <= {D1[0], ddr3_write_0_control_control_done};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
    end
    end
assign  done_pos_edge = ~D1[1] & D1[0];

//真正的传输开始与结束状态标志	
always @(posedge clk or posedge sys_rst_n)
	if (sys_rst_n == 1'b0)
		status_register  <= 1'd0;
	else if(pos_edge)
		status_register  <= 1'd0;
	else if(done_pos_edge)
		status_register  <= 1'd1;
//control_done信号产生后
//使用组合逻辑赋值，这样使能和数据地址才能对应
assign ddr3_write_0_control_control_write_base = (flag == 1'b1) ? buffer0: buffer1; //地址


dvp_ddr3_top #(
    .USER_DATA_WIDTH     (32),
    .AVALON_DATA_WIDTH   (32),
    .MEMORY_BASED_FIFO   (1),
    .FIFO_DEPTH          (256),
    .FIFO_DEPTH_LOG2     (8),
    .ADDRESS_WIDTH       (32),
    .BURST_CAPABLE       (1),
    .MAXIMUM_BURST_COUNT (16),
    .BURST_COUNT_WIDTH   (5)
) dvp_ddr3_top_0 (
    .clk                (clk_50_clk),                                     //         clock.clk
    .reset_n            (~rst_controller_reset_out_reset),                //         reset.reset_n
    .as_address         (mm_interconnect_2_dvp_ddr3_top_0_as_address),    //            as.address
    .as_write           (mm_interconnect_2_dvp_ddr3_top_0_as_write),      //              .write
    .as_writedata       (mm_interconnect_2_dvp_ddr3_top_0_as_writedata),  //              .writedata
    .as_read            (mm_interconnect_2_dvp_ddr3_top_0_as_read),       //              .read
    .as_readdata        (mm_interconnect_2_dvp_ddr3_top_0_as_readdata),   //              .readdata
    .chipselect         (mm_interconnect_2_dvp_ddr3_top_0_as_chipselect), //              .chipselect
    .master_address     (dvp_ddr3_top_0_avalon_master_address),           // avalon_master.address
    .master_burstcount  (dvp_ddr3_top_0_avalon_master_burstcount),        //              .burstcount
    .master_byteenable  (dvp_ddr3_top_0_avalon_master_byteenable),        //              .byteenable
    .master_waitrequest (dvp_ddr3_top_0_avalon_master_waitrequest),       //              .waitrequest
    .master_write       (dvp_ddr3_top_0_avalon_master_write),             //              .write
    .master_writedata   (dvp_ddr3_top_0_avalon_master_writedata),         //              .writedata
    .cnt_go             (dvp_ddr3_top_0_wire_cnt_go),                     //          wire.cnt_go
    .dvp_pclk           (dvp_ddr3_top_0_dvp_dvp_pclk),                    //           dvp.dvp_pclk
    .dvp_href           (dvp_ddr3_top_0_dvp_dvp_href),                    //              .dvp_href
    .dvp_vsync          (dvp_ddr3_top_0_dvp_dvp_vsync),                   //              .dvp_vsync
    .dvp_data           (dvp_ddr3_top_0_dvp_dvp_data)                     //              .dvp_data
);


endmodule

