`timescale  1ns/1ns
module  tb_vga_ctrl();

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define
parameter   H_VALID   =   10'd400 ,   //行有效数据
            H_TOTAL   =   10'd455 ;   //行扫描周期
parameter   V_SYNC    =   10'd9   ,   //场同步
            V_BACK    =   10'd20  ,   //场时序后沿
            V_VALID   =   10'd320 ,   //场有效数据
            V_FRONT   =   10'd16   ,   //场时序前沿
            V_TOTAL   =   10'd365 ;   //场扫描周期
//reg   define
reg             sys_clk         ;   //模拟dvp时钟信号
reg             clk         ;   //模拟时钟信号
reg             sys_rst_n       ;   //模拟复位信号
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

parameter USER_DATA_WIDTH = 128;		//输入位宽
wire vga_clk;
wire vga_de;
wire vga_hsync;
wire vga_vsync;
wire [23:0]vga_rgb;

wire read_req;
wire [USER_DATA_WIDTH-1:0]read_data;

wire            cmos_vsync_begin    ;   //有效图像使能信号
wire            cmos_vsync_end ;   //有效图像数据

//例化
vga_ctrl #(
    .USER_DATA_WIDTH     (128)
)
vga_ctrl_inst(
    .clk             (sys_clk     ),  //时钟信号
    .sys_rst_n       (sys_rst_n   ),  //复位信号

    .vga_clk         (vga_clk     ),  //摄像头像素时钟
    .vga_de          (vga_de    ),  //摄像头行同步信号
    .vga_hsync       (vga_hsync   ),  //摄像头场同步信号
    .vga_vsync       (vga_vsync    ),  //摄像头图像数据
    .vga_rgb         (vga_rgb),         //图像数据

    .read_req        (read_req   ),    //场同步开始
    .read_data       (read_data   ),    //场同步结束

    .cmos_vsync_begin   (cmos_vsync_begin   ),    //场同步开始
    .cmos_vsync_end     (cmos_vsync_end   )    //场同步结束
);



//仿真其读写帧控制逻辑
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
// always @(posedge sys_clk or negedge sys_rst_n)
// 	if (sys_rst_n == 1'b0)
// 		control_go  <= 1'd0;
// 	else if (start_cap)begin
// 		if(cmos_vsync_end)
// 			control_go  <= 1'd1;
// 		else
// 			control_go  <= 1'd0;
// 	end
// 	else
// 		control_go  <= 1'd0;
// assign ddr3_write_0_control_control_go=control_go;

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
always @(posedge clk or negedge sys_rst_n)
	if (sys_rst_n == 1'b0) begin
		hps_start_cap  <= 1'b0; 
    end  
    else if(hps_start_cap==0 && pos_edge==1 ) begin
        hps_start_cap <= 1;
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




// //仿真ddr3_read
// parameter AVALON_DATA_WIDTH = 128;	//输出位宽128
// parameter MEMORY_BASED_FIFO = 1;	//使用内部memory	
// parameter FIFO_DEPTH = 256;		//FIFO深度为256=8192/32
// parameter FIFO_DEPTH_LOG2 = 8;		//FIFO深度的位宽
// parameter ADDRESS_WIDTH = 32;		//地址线宽度
// parameter BURST_CAPABLE = 1;		//使能突发
// parameter MAXIMUM_BURST_COUNT = 16; //最大突发长度16
// parameter BURST_COUNT_WIDTH = 5;		//突发长度位宽+1
// //master接口
// wire	[ADDRESS_WIDTH-1:0]			master_address;
// wire								master_read;				
// wire	[(AVALON_DATA_WIDTH/8)-1:0]	master_byteenable;
// wire	[AVALON_DATA_WIDTH-1:0]		master_readdata;			
// wire								master_readdatavalid;
// wire	[BURST_COUNT_WIDTH-1:0]		master_burstcount;		
// wire								master_waitrequest;
// //软件复位
// wire        			   soft_reset;             
// //control接口
// wire    [31:0] 			   control_read_base;     
// wire    [31:0] 			   control_read_length;   
// wire        			   control_fixed_location;        
// wire        			   control_done;  	
// wire        			   control_early_done;  	
// //user接口
// wire        			   user_read_clk;         
// wire        			   user_read_buffer;      
// wire        			   user_data_available;       
// wire [USER_DATA_WIDTH-1:0] user_buffer_data;   
// //例化ddr3_read
// ddr3_read #(
//     .USER_DATA_WIDTH     (USER_DATA_WIDTH),
//     .AVALON_DATA_WIDTH   (AVALON_DATA_WIDTH),
//     .MEMORY_BASED_FIFO   (MEMORY_BASED_FIFO),
//     .FIFO_DEPTH          (FIFO_DEPTH),
//     .FIFO_DEPTH_LOG2     (FIFO_DEPTH_LOG2),
//     .ADDRESS_WIDTH       (ADDRESS_WIDTH),
//     .BURST_CAPABLE       (BURST_CAPABLE),
//     .MAXIMUM_BURST_COUNT (MAXIMUM_BURST_COUNT),
//     .BURST_COUNT_WIDTH   (BURST_COUNT_WIDTH)
// ) ddr3_read_0 (
//     .clk                    (clk),                                     
//     .reset_n                (sys_rst_n),      		 //低电平复位         
//     .soft_reset             (soft_reset),   		 //高电平复位
// 	//control接口
//     .control_read_base      (control_read_base),      //读地址
//     .control_read_length    (control_read_length),    //读长度
//     .control_fixed_location (),             
//     .control_go             (ddr3_write_0_control_control_go),            //开始写信号
//     .control_done           (control_done),          //读完信号
//     .control_early_done     (control_early_done),    //快读完信号
// 	//user接口
//     .user_read_clk          (user_read_clk),    	 //读时钟    
//     .user_read_buffer       (user_read_buffer), 	 //读请求      
//     .user_buffer_data       (user_buffer_data),  	 //读数据   
//     .user_data_available    (user_data_available),   //fifo是否空    
// 	//avalon_mm_master接口
//     .master_address         (master_address),        
//     .master_read            (master_read),          
//     .master_byteenable      (master_byteenable),     
//     .master_readdata        (master_readdata),      
//     .master_readdatavalid   (master_readdatavalid),  //读数据有效信号
//     .master_burstcount      (master_burstcount),     
//     .master_waitrequest     (master_waitrequest)     
// );


// //address,read,beginbursttransfer,burstcount,waitrequst,readdata,readdatavalid
reg [9:0]cnt_go;//记录目前启动了多少次
always @(posedge vga_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_go <= 8'b0;
    else if(vga_de==1)
        cnt_go <= cnt_go+1'b1;
    else
        cnt_go <= 8'b0;

// //address,read,beginbursttransfer,burstcount,waitrequst,readdata,readdatavalid
reg [9:0]cnt_go1;//记录目前启动了多少次
always @(posedge vga_de or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_go1 <= 10'b0;
    else
        cnt_go1 <= cnt_go1+1'b1;

//使用边沿检测检测启动信号上升沿，只会持续一个时钟周期
reg [1:0]D2;
wire de_edge;
always @(posedge vga_clk or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)begin
        D2 <= 2'b00;
    end
    else begin
        D2 <= {D2[0], vga_vsync};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
    end
    end
assign  de_edge = ~D2[1] & D2[0];

reg  flag1;//记录第一个vga_de
always @(posedge vga_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        flag1 <= 1'b0;
    else if(de_edge==1)
        flag1 <= 1'b1;
    else if(vga_de==1)
        flag1 <= 1'b0;
    else
        flag1 <= flag1;



reg [1:0]D3;
wire GO_edge;
always @(posedge vga_clk or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)begin
        D3 <= 2'b00;
    end
    else begin
        D3 <= {D3[0], flag1};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
    end
    end
assign  GO_edge = D3[1] & ~D3[0];


always @(posedge vga_clk or negedge sys_rst_n)
	if (sys_rst_n == 1'b0)
		control_go  <= 1'd0;
	else if (GO_edge==1)begin
			control_go  <= 1'd1;
	end
	else
		control_go  <= 1'd0;
assign ddr3_write_0_control_control_go=control_go;

//
//read_data1:在读请求下产生的读数据
reg [USER_DATA_WIDTH-1:0] read_data1;
always@(posedge vga_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        read_data1 <=  128'h12345678123456781234567812345678;
    else    if(read_req == 1'b1) 
        read_data1 <=  read_data1 + 1'b1;
    else
        read_data1 <=  read_data1;
// assign user_read_clk=vga_clk;//读时钟为vga时钟
// assign user_read_buffer=read_req;//读请求由读请求与捕捉有效信号共同作用
assign read_data=read_data1;//读数据赋值给read_data
// assign soft_reset=0;//读数据赋值给read_data
// assign control_read_base=32'h10000000;//读数据赋值给read_data
// assign control_read_length=32'h0012c000;//读数据赋值给read_data
// reg  [5:0]cnt;
// reg read;
// always@(posedge clk or  negedge sys_rst_n)
//     if(sys_rst_n == 6'b0)
//         cnt <=  0;
//     else    if(cnt == 6'd16) begin
//         cnt <= 0;
//         read <= 0;
//     end
//     else if(master_read)
//         read <= 1'b1;
//     else if(read)
//         cnt <=  cnt + 1'b1;
// 	else 
// 		cnt <= cnt;

// assign master_readdatavalid=(cnt<16&&read==1)?1'b1:1'b0;
// //waitrequst
// assign master_waitrequest=1'b0;//waitrequest一直为低电平
// assign master_readdata=read_data1;//waitrequest一直为低电平


//测试Buffer切换
parameter LENGTH =  32'h0005DC00;			//一帧长度
parameter BUFFER0 = 32'h30880000;			//写地址默认为BUFFER0启动
parameter BUFFER1 = BUFFER0+LENGTH;			//读地址默认为BUFFER1启动
parameter BUFFER2 = BUFFER1+LENGTH;			//为hps传输图片的地址

//pinpang_flag翻转
reg vga_done;
reg dvp_done;
reg pinpang_flag;

initial
  begin
    dvp_done   <=  1'b0  ;
    vga_done   <=  1'b0  ;
  end
always  #400 dvp_done = ~dvp_done;
always  #300 vga_done = ~vga_done;

always @(posedge vga_done or posedge dvp_done or negedge sys_rst_n)
    if (sys_rst_n == 1'b0)
        pinpang_flag  <= 1'd0;
    else if(vga_done&dvp_done)
        pinpang_flag <= ~pinpang_flag;
    else
        pinpang_flag  <= pinpang_flag;

// //地址选择
// wire [31:0]dvp_address;
// wire [31:0]vga_address;

// // assign dvp_address=(pinpang_flag==0)?BUFFER0:BUFFER1;//dvp默认使用BUFFER0
// // assign vga_address=(pinpang_flag==0)?BUFFER1:BUFFER0;//vga默认使用BUFFER1






//检测两个done信号上升沿
reg [1:0]D4;
wire dvp_done_posedge;
always @(posedge clk or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)begin
        D4 <= 2'b00;
    end
    else begin
        D4 <= {D4[0], dvp_done};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
    end
    end
assign  dvp_done_posedge = ~D4[1] & D4[0];

reg [1:0]D5;
wire vga_done_posedge;
always @(posedge clk or negedge sys_rst_n)begin
    if(sys_rst_n == 1'b0)begin
        D5 <= 2'b00;
    end
    else begin
        D5 <= {D5[0], vga_done};  	//D[1]表示前一状态，D[0]表示后一状态（新数据） 
    end
    end
assign  vga_done_posedge = ~D5[1] & D5[0];

//状态机操作
//状态定义
parameter IDLE = 4'b0001, //初始状态
          Wbuffer0 = 4'b0010, //写 RAM1 状态
          wbuffer1_rbuffer0 = 4'b0100, //写 RAM2 读 RAM1 状态
          Wbuffer0_rbuffer1 = 4'b1000; //写 RAM1 读 RAM2 状态
//信号定义
reg [3:0] state; //状态机状态
reg       once_flag; //第一次写信号，不进行读
//状态机状态跳转
always@(negedge clk or negedge sys_rst_n)//使用下降沿进行状态跳转，防止对上升沿数据采样造成影响
    if(sys_rst_n == 1'b0) begin
        state <= IDLE;
        once_flag <= 0;
    end
    else case(state)
        IDLE://只在初始进入一次，跳转到写buffer0状态
            if(once_flag == 1'b0) begin
                state <= Wbuffer0;
                once_flag <= 1;
            end
        Wbuffer0://第一次写完buffer0，跳转到写buffer1读buffer0状态
            if(dvp_done_posedge == 1)
                state <= wbuffer1_rbuffer0;
        wbuffer1_rbuffer0://写完buffer1读完buffer0，跳转到写buffer0读buffer1状态
            if(dvp_done_posedge)//该值为0代表写buffer0读buffer1,以写入为目标进行切换
                state <= Wbuffer0_rbuffer1;
        Wbuffer0_rbuffer1://RAM1 数据写完之后，跳转到写 RAM2 读 RAM1 状态
            if(dvp_done_posedge)
                state <= wbuffer1_rbuffer0;
        default:
        state <= IDLE;
    endcase
//根据状态进行地址赋值
reg [31:0]dvp_address1;
reg [31:0]vga_address1;
reg dvp_go1;
reg vga_go1;
always@(*)
    case(state)
        IDLE:
            begin
                dvp_address1 = 32'b0;
                vga_address1 = 32'b0;
				dvp_go1=0;
				vga_go1=0;
            end
        Wbuffer0:
            begin
				dvp_go1=1;//启动dvp捕获
                dvp_address1 = BUFFER0;
                vga_address1 = 0;
            end
        wbuffer1_rbuffer0:
            begin
				vga_go1=1;//启动vga捕获
                dvp_address1 = BUFFER1;
                vga_address1 = BUFFER0;
            end
        Wbuffer0_rbuffer1:
            begin
                dvp_address1 = BUFFER0;
                vga_address1 = BUFFER1;
            end
        default:;
    endcase

assign dvp_address=dvp_address1;//dvp默认使用BUFFER0
assign vga_address=vga_address1;//vga默认使用BUFFER1
assign dvp_go=dvp_go1;//dvp默认使用BUFFER0
assign vga_go=vga_go1;//vga默认使用BUFFER1


endmodule

