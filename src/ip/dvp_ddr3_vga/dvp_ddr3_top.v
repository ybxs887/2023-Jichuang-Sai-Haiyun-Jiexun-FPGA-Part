module dvp_ddr3_top_me
#(
//����
	parameter USER_DATA_WIDTH = 128,	//����λ��128
	parameter AVALON_DATA_WIDTH = 128,	//���λ��128
	parameter MEMORY_BASED_FIFO = 1,	//ʹ���ڲ�memory	
	parameter FIFO_DEPTH = 256,			//FIFO���Ϊ256=8192/32
	parameter FIFO_DEPTH_LOG2 = 8,		//FIFO��ȵ�λ��
	parameter ADDRESS_WIDTH = 32,		//��ַ�߿��
	parameter BURST_CAPABLE = 1,		//ʹ��ͻ��
	parameter MAXIMUM_BURST_COUNT = 16, //���ͻ������16
	parameter BURST_COUNT_WIDTH = 5,		//ͻ������λ��+1
			//����ַ����
	parameter LENGTH =  32'h0001f400,			//һ֡����
	parameter RESIZE_LENGTH =  32'h0015f90,			//һ֡����
	parameter BUFFER0 = 32'h30880000			//д��ַĬ��ΪBUFFER0����
)
(
	input 					clk,			 //50Mʱ��
	input 					reset_n,         //Ӳ���͵�ƽ���븴λ
	//dvpʱ������ӿ�
    input   wire            dvp_pclk     ,   //����ͷ����ʱ��
    input   wire            dvp_href     ,   //����ͷ��ͬ���ź�
    input   wire            dvp_vsync    ,   //����ͷ��ͬ���ź�
    input   wire    [ 7:0]  dvp_data     ,   //����ͷͼ������
	//avalon_mm_slave�ӿ�
	input 					chipselect,
	input [1:0]				as_address,
	input 					as_write,
	input [31:0]			as_writedata,
	input 					as_read,
	output wire [31:0]		as_readdata,
	//avalon_mm_master�ӿ�
	output wire	[ADDRESS_WIDTH-1:0]			master_address,
	output wire								master_write,				
	output wire	[(AVALON_DATA_WIDTH/8)-1:0]	master_byteenable,
	output wire	[AVALON_DATA_WIDTH-1:0]		master_writedata,			
	output wire	[BURST_COUNT_WIDTH-1:0]		master_burstcount,			
	input									master_waitrequest,
	//avalon_mm_master�ӿ�
	output wire	[ADDRESS_WIDTH-1:0]			master_address1,
	output wire								master_write1,				
	output wire	[(AVALON_DATA_WIDTH/8)-1:0]	master_byteenable1,
	output wire	[AVALON_DATA_WIDTH-1:0]		master_writedata1,			
	output wire	[BURST_COUNT_WIDTH-1:0]		master_burstcount1,			
	input									master_waitrequest1,
	//���Խӿ�
	output reg [7:0]		cnt_go,			  //��¼Ŀǰhps�����˶��ٴ�
	
	//��ַ����
	input					[31:0]	dvp_address,
	//��������
	input									dvp_go,
	//done�ź����
	output									dvp_done,
	//��дbuffer��״̬
	input									buffer_status
);
//=======================================================
//��������
//=======================================================
	parameter BUFFER1 = BUFFER0+LENGTH;			//����ַĬ��ΪBUFFER1����
	parameter BUFFER2 = BUFFER1+LENGTH;			//Ϊhps����ͼƬ�ĵ�ַ
	parameter RESIZE_USER_DATA_WIDTH = 32;		//resize���λ��32
	
//=======================================================
//�źŶ���
//=======================================================

//ddr3_write
	//�����λ
	wire        			   soft_reset;             
	//control�ӿ�
	wire    [31:0] 			   control_write_base;     
	wire    [31:0] 			   control_write_length;   
	wire        			   control_done;           
	wire        			   control_fixed_location; 
	wire        			   control_go;             
	//user�ӿ�
	wire        			   user_write_clk;         
	wire        			   user_write_buffer;      
	wire        			   user_buffer_full;       
	wire [USER_DATA_WIDTH-1:0] user_buffer_data;       

//dvp_ddr3_ctrl
	wire 			hps_control_go1;   //hps���������ź�
	wire 	[1:0]	master_ctrl_en;    //���ƼĴ��������ࣩ
	wire 			status;            //״̬�Ĵ�����Ϊ1��ʾ������ɣ�Ϊ0�������ڴ���

//dvp_rgb888
	wire            rgb888_wr_en;      //��Чͼ��ʹ���ź�
	wire    [USER_DATA_WIDTH-1:0]  rgb888_data_out;   //��Чͼ�����ݣ���ǰ��128bit
	wire            cmos_vsync_begin;  //��Чͼ��ʹ���ź�
	wire            cmos_vsync_end;    //��Чͼ������
	
//resize_top
	wire            resize_pclk;
	wire            resize_wr_en;      //��Чͼ��ʹ���ź�
	wire    [RESIZE_USER_DATA_WIDTH-1:0]  resize_data_out;   //��Чͼ�����ݣ���ǰ��32bit
	wire            resize_vsync_begin;  //��Чͼ��ʹ���ź�
	wire            resize_vsync_end;    //��Чͼ������



//�����ź�
	//д֡������
	parameter MAXFRAME= 8'd1;//����һ��д1֡
	//֡�����־
	reg start_cap;			//��ʼ��׽֡�źţ���hps���𣬸ߵ�ƽ��Ч��������MAXFRAME֡����λ0
	reg en_cap;				//������׽֡�źţ�start_cap��Чʱ����ͬ���ߵ�ƽ����ʱ��ʼ��Ч
	//�����ź�
	reg control_go1;		//����ddr3_write�źŵļĴ���
	reg hps_start_cap1;		//������׽�ź�
	wire hps_start_cap;  	//hps�����������ź�
	reg [7:0]frame_count;	//֡�����������ڿ��ƶ�д����֡����MAXFRAMEλ����ͬ
	//���ؼ��
	reg [1:0]D;				//���ؼ��Ĵ���
	reg [1:0]D1;
	wire pos_edge;			//hps������׽֡�����أ���hps_start_cap1������
	wire done_pos_edge;		//��������ź������أ���control_done������
	//����״̬�ź�
	reg status_register;	//status����״̬�Ĵ���
	//�¼���
	wire        			   control_done1;  
//=======================================================
//����
//=======================================================

//����ddr3_write
ddr3_write #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH),
    .AVALON_DATA_WIDTH   (AVALON_DATA_WIDTH),
    .MEMORY_BASED_FIFO   (MEMORY_BASED_FIFO),
    .FIFO_DEPTH          (FIFO_DEPTH),
    .FIFO_DEPTH_LOG2     (FIFO_DEPTH_LOG2),
    .ADDRESS_WIDTH       (ADDRESS_WIDTH),
    .BURST_CAPABLE       (BURST_CAPABLE),
    .MAXIMUM_BURST_COUNT (MAXIMUM_BURST_COUNT),
    .BURST_COUNT_WIDTH   (BURST_COUNT_WIDTH)
) ddr3_write_0 (
    .clk                    (clk),                                     
    .reset_n                (reset_n),      		 //�͵�ƽ��λ         
    .soft_reset             (soft_reset),   		 //�ߵ�ƽ��λ
	//control�ӿ�
    .control_write_base     (dvp_address),    //д��ַ
    .control_write_length   (control_write_length),  //д����
    .control_done           (control_done),          //д���ź�
    .control_fixed_location (),             
    .control_go             (control_go),            //��ʼд�ź�
	//user�ӿ�
    .user_write_clk         (user_write_clk),    	 //дʱ��    
    .user_write_buffer      (user_write_buffer), 	 //д����      
    .user_buffer_data       (user_buffer_data),  	 //д����   
    .user_buffer_full       (user_buffer_full),      
	//avalon_mm_master�ӿ�
    .master_address         (master_address),        
    .master_write           (master_write),          
    .master_byteenable      (master_byteenable),     
    .master_writedata       (master_writedata),      
    .master_burstcount      (master_burstcount),     
    .master_waitrequest     (master_waitrequest)     
);

//����resize_ddr3_write
ddr3_write #(
    .USER_DATA_WIDTH     (RESIZE_USER_DATA_WIDTH),
    .AVALON_DATA_WIDTH   (AVALON_DATA_WIDTH),
    .MEMORY_BASED_FIFO   (MEMORY_BASED_FIFO),
    .FIFO_DEPTH          (FIFO_DEPTH),
    .FIFO_DEPTH_LOG2     (FIFO_DEPTH_LOG2),
    .ADDRESS_WIDTH       (ADDRESS_WIDTH),
    .BURST_CAPABLE       (BURST_CAPABLE),
    .MAXIMUM_BURST_COUNT (MAXIMUM_BURST_COUNT),
    .BURST_COUNT_WIDTH   (BURST_COUNT_WIDTH)
) resize_ddr3_write_0 (
    .clk                    (clk),                                     
    .reset_n                (reset_n),      		 //�͵�ƽ��λ         
    .soft_reset             (soft_reset),   		 //�ߵ�ƽ��λ
	//control�ӿ�
    .control_write_base     (dvp_address+4*LENGTH),    //д��ַ
    .control_write_length   (RESIZE_LENGTH),  //д����
    .control_done           (control_done1),          //д���ź�
    .control_fixed_location (),             
    .control_go             (control_go),            //��ʼд�ź�
	//user�ӿ�
    .user_write_clk         (resize_pclk),    	 //дʱ��    
    .user_write_buffer      (resize_wr_en), 	 //д����      
    .user_buffer_data       (resize_data_out),  	 //д����   
    .user_buffer_full       (),      
	//avalon_mm_master�ӿ�
    .master_address         (master_address1),        
    .master_write           (master_write1),          
    .master_byteenable      (master_byteenable1),     
    .master_writedata       (master_writedata1),      
    .master_burstcount      (master_burstcount1),     
    .master_waitrequest     (master_waitrequest1)     
);

//����dvp_ddr3_ctrl
dvp_ddr3_ctrl dvp_ddr3_ctrl_0 (
	.clk                 (clk),                   
	.reset_n             (reset_n),       //�͵�ƽ��λ           
	//avalon_mm_slave�ӿ�
	.as_address          (as_address),         
	.as_write            (as_write),            
	.as_writedata        (as_writedata),        
	.as_read             (as_read),             
	.as_readdata         (as_readdata),       
	.chipselect          (chipselect),         
	//control�ӿ�
	.control_user_base   (control_write_base),    
	.control_user_length (control_write_length),  
	.control_go          (hps_start_cap),  			//hpsдһ֡����
	.control_en          (master_ctrl_en),  		//Ԥ�����ƼĴ���
	.control_state       (buffer_status)            		//����״̬
);

//����dvp_rgb888
dvp_rgb888 #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH)
)
dvp_rgb888_inst(
    .sys_rst_n       	(reset_n     ),  	 	 //��λ�źţ��͵�ƽ
	//dvpʱ������ӿ�
    .dvp_pclk        	(dvp_pclk    ), 	     //����ͷ����ʱ��
    .dvp_href        	(dvp_href    ),     	 //����ͷ��ͬ���ź�
    .dvp_vsync       	(dvp_vsync   ), 	 	 //����ͷ��ͬ���ź�
    .dvp_data        	(dvp_data    ), 	 	 //����ͷͼ������
	//����
    .rgb888_wr_en       (rgb888_wr_en   ),   	 //ͼ��������Чʹ���ź�
    .rgb888_data_out    (rgb888_data_out),   	 //ͼ������
	//��ͬ������
	.cmos_vsync_begin   (cmos_vsync_begin),  	 //��ͬ����ʼ
    .cmos_vsync_end     (cmos_vsync_end   )   	 //��ͬ������
);

//����resize_top
resize_top  #(
    .USER_DATA_WIDTH     (RESIZE_USER_DATA_WIDTH)
 )
 resize_top_inst(
    .sys_rst_n          (reset_n     ),  //��λ�ź�

    .dvp_pclk_in        (dvp_pclk     ),  //����ͷ����ʱ��
    .dvp_href_in        (dvp_href    ),  //����ͷ��ͬ���ź�
    .dvp_vsync_in       (dvp_vsync   ),  //����ͷ��ͬ���ź�
    .dvp_data_in        (dvp_data    ),  //����ͷͼ������

	.resize_pclk		(resize_pclk),  
    .resize_wr_en       (resize_wr_en),  //ͼ��������Чʹ���ź�
    .resize_data_out    (resize_data_out),   //ͼ������

    .cmos_vsync_begin   (resize_vsync_begin   ),    //��ͬ����ʼ
    .cmos_vsync_end     (resize_vsync_end   )    //��ͬ������
);


//=======================================================
//�����߼�
//=======================================================

//����߼���ֵ
assign user_write_clk=dvp_pclk;//дʱ��Ϊdvpʱ��
assign user_write_buffer=rgb888_wr_en&en_cap;//д������������Ч�벶׽��Ч�źŹ�ͬ����
assign user_buffer_data=rgb888_data_out;//д�����ȴո�32λ
assign soft_reset=1'b0;//��ʹ�������λ����ʱ���ã�
assign dvp_done=control_done;
//dvp_pclk�µ�ʱ��

	//start_cap	
	always @(posedge dvp_pclk or negedge reset_n)
		if (reset_n == 1'b0)
			start_cap  <= 1'd0;
		else if(hps_start_cap1)
			start_cap <= 1'd1;
		else if(en_cap && cmos_vsync_begin) 
		begin
			start_cap  <= 1'd0;
		end
		else
			start_cap  <= start_cap;

	//en_cap
	always @(posedge dvp_pclk or negedge reset_n)
		if (reset_n == 1'b0)
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
	always @(posedge dvp_pclk or negedge reset_n)
		if (reset_n == 1'b0)
			control_go1  <= 1'd0;
		else if (start_cap)begin
			if(cmos_vsync_end)
				control_go1  <= 1'd1;
			else
				control_go1  <= 1'd0;
		end
		else
			control_go1  <= 1'd0;
	assign control_go=control_go1;//��reg��ֵ��wire

	//��ȡ֡������
	always @(posedge dvp_pclk or negedge reset_n)
		if (reset_n == 1'b0) begin
			frame_count  <= 8'd0;
		end  
		else if(frame_count== MAXFRAME) begin//����Ѿ����һ��
			frame_count  <= 8'd0;
		end
		else if(control_go== 1'b1)
			frame_count <= frame_count + 1'b1;
		else
			frame_count  <= frame_count;

			
//clk_50�µ�ʱ��

	//ʹ�ñ��ؼ���������ź������أ�ֻ�����һ��ʱ������(����dvpʱ�Ӽ��)
	always @(posedge clk or negedge reset_n)begin
			if(reset_n == 1'b0)begin
				D <= 2'b00;
			end
			else begin
				D <= {D[0], dvp_go};  	//D[1]��ʾǰһ״̬��D[0]��ʾ��һ״̬�������ݣ� 
			end
		end
	assign  pos_edge = ~D[1] & D[0];
		
	//ʹ�ñ��ؼ����done�ź������أ�ֻ�����һ��ʱ������(����dvpʱ�Ӽ��)
	always @(posedge clk or negedge reset_n)begin
			if(reset_n == 1'b0)begin
				D1 <= 2'b00;
			end
			else begin
				D1 <= {D1[0], control_done};  	//D[1]��ʾǰһ״̬��D[0]��ʾ��һ״̬�������ݣ� 
			end
		end
	assign  done_pos_edge = ~D1[1] & D1[0];
	
	//���ﵽһ�α�־�źŵ���������
	// always @(posedge clk)
		// if(hps_start_cap1==1'b0 && pos_edge==1'b1 ) begin
			// hps_start_cap1 <= 1'b1;
		// end
		// else if ((frame_count!=MAXFRAME)) begin
			// hps_start_cap1 <= hps_start_cap1;
		// end 
		// else begin
			// hps_start_cap1  <= 1'b0; 
		// end
	always @(posedge clk or negedge reset_n)//����һ��30֡����
		if (reset_n == 1'b0) begin
			hps_start_cap1  <= 1'b0; 
		end  
		else if(hps_start_cap1==0 && pos_edge==1 ) begin
			hps_start_cap1 <= 1;
		end

	//�����Ĵ��俪ʼ�����״̬status��־
	always @(posedge clk or negedge reset_n)
		if (reset_n == 1'b0)
			status_register  <= 1'd0;
		else if(pos_edge)//��⵽�����ź������ؾ���Ϊ���ڴ���״̬
			status_register  <= 1'd0;
		else if(done_pos_edge)//��⵽done�ź������ؾ���Ϊ�������״̬
			status_register  <= 1'd1;
	assign  status = status_register;

	
//�����ź�

	//���������������ڲ���
	always @(posedge pos_edge or negedge reset_n)
		if(reset_n == 1'b0)
			cnt_go <= 1'b0;
		else
			cnt_go <= cnt_go+1'b1;
	
endmodule

