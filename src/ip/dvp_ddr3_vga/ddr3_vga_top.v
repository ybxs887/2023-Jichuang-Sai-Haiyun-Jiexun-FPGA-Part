module ddr3_vga_top_me
#(
//����
	parameter USER_DATA_WIDTH = 128,	//����λ��128
	parameter AVALON_DATA_WIDTH = 128,	//���λ��128
	parameter MEMORY_BASED_FIFO = 1,	//ʹ���ڲ�memory	
	parameter FIFO_DEPTH = 256,			//FIFO���Ϊ256=8192/32
	parameter FIFO_DEPTH_LOG2 = 8,		//FIFO��ȵ�λ��
	parameter ADDRESS_WIDTH = 32,		//��ַ�߿��
	parameter BURST_CAPABLE = 0,		//ʹ��ͻ��
	parameter MAXIMUM_BURST_COUNT = 16, //���ͻ������16
	parameter BURST_COUNT_WIDTH = 5,		//ͻ������λ��+1
		//����ַ����
	parameter LENGTH =  32'h0005DC00,			//һ֡����
	parameter BUFFER0 = 32'h30880000			//д��ַĬ��ΪBUFFER0����
)
(
	input 					clk,			 //50Mʱ��
	input 					reset_n,         //Ӳ���͵�ƽ���븴λ
	//vgaʱ������ӿ�
    output  wire           	vga_clk     ,   //���vgaʱ��,Ƶ��5MHz
    output  wire            vga_de    	,   //��Ч����ѡͨ�ź�DE
    output  wire            vga_hsync   ,   //�����ͬ���ź�
    output  wire            vga_vsync   ,   //�����ͬ���ź�
    output  wire    [23:0]  vga_rgb     ,   //���24bit������Ϣ
	//avalon_mm_slave�ӿ�
	input 					chipselect,
	input [1:0]				as_address,
	input 					as_write,
	input [31:0]			as_writedata,
	input 					as_read,
	output wire [31:0]		as_readdata,
	//avalon_mm_master�ӿ�
	output wire	[ADDRESS_WIDTH-1:0]			master_address,
	output wire								master_read,				
	output wire	[(AVALON_DATA_WIDTH/8)-1:0]	master_byteenable,
	input wire	[AVALON_DATA_WIDTH-1:0]		master_readdata,			
	input									master_readdatavalid,
	output wire	[BURST_COUNT_WIDTH-1:0]		master_burstcount,			
	input									master_waitrequest,
	output									flag,
	
	//��ַ����
	input							[31:0]			vga_address,
	//��������
	input									vga_go,
	//done�ź����
	output									vga_done,
	//��дbuffer��״̬
	input									buffer_status	
	);
//=======================================================
//��������
//=======================================================
	parameter BUFFER1 = BUFFER0+LENGTH;			//����ַĬ��ΪBUFFER1����
	parameter BUFFER2 = BUFFER1+LENGTH;			//Ϊhps����ͼƬ�ĵ�ַ
//=======================================================
//�źŶ���
//=======================================================
//vgaʱ��
	wire        			   clk_5M;             
//ddr3_read
	//�����λ
	wire        			   soft_reset;             
	//control�ӿ�
	wire    [31:0] 			   control_read_base;     
	wire    [31:0] 			   control_read_length;   
	wire        			   control_fixed_location; 
	wire        			   control_go;            
	wire        			   control_done;  	
	wire        			   control_early_done;  	
	//user�ӿ�
	wire        			   user_read_clk;         
	wire        			   user_read_buffer;      
	wire        			   user_data_available;       
	wire [USER_DATA_WIDTH-1:0] user_buffer_data;       
	
//ddr3_vga_ctrl
	wire 			hps_start_cap;  	//hps�����������ź�
	wire 	[1:0]	master_ctrl_en;    //���ƼĴ��������ࣩ
	wire 			status;            //״̬�Ĵ�����Ϊ1��ʾ������ɣ�Ϊ0�������ڴ���

//vga_ctrl
	wire            cmos_vsync_begin;  //��Чͼ��ʹ���ź�
	wire            cmos_vsync_end;    //��Чͼ������
	wire            read_req;     	   //���������ź�
	wire [USER_DATA_WIDTH-1:0]  read_data; //������

//�����ź�
	//д֡������
	parameter MAXFRAME= 8'd1;//����һ��д1֡
	//֡�����־
	reg start_cap;			//��ʼ��׽֡�źţ���hps���𣬸ߵ�ƽ��Ч��������MAXFRAME֡����λ0
	reg en_cap;				//������׽֡�źţ�start_cap��Чʱ����ͬ���ߵ�ƽ����ʱ��ʼ��Ч
	//�����ź�
	reg control_go1;		//����ddr3_write�źŵļĴ���
	reg hps_start_cap1;		//������׽�ź�
	reg [7:0]frame_count;	//֡�����������ڿ��ƶ�д����֡����MAXFRAMEλ����ͬ
	//���ؼ��
	reg [1:0]D;				//���ؼ��Ĵ���
	reg [1:0]D1;
	wire pos_edge;			//hps������׽֡�����أ���hps_start_cap1������
	wire done_pos_edge;		//��������ź������أ���control_done������
	//����״̬�ź�
	reg status_register;	//status����״̬�Ĵ���
	//���Խӿ�
	reg [7:0]		cnt_go;			  //��¼Ŀǰhps�����˶��ٴ�
	
	
//=======================================================
//����
//=======================================================

//����5Mʱ��
vga_pll_0002 vga_pll_inst (
	.refclk   (clk),   //  refclk.clk
	.rst      (~reset_n),      //   reset.reset�ߵ�ƽ��λ
	.outclk_0 (clk_5M) // outclk0.clk
);

//����ddr3_read
ddr3_read #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH),
    .AVALON_DATA_WIDTH   (AVALON_DATA_WIDTH),
    .MEMORY_BASED_FIFO   (MEMORY_BASED_FIFO),
    .FIFO_DEPTH          (FIFO_DEPTH),
    .FIFO_DEPTH_LOG2     (FIFO_DEPTH_LOG2),
    .ADDRESS_WIDTH       (ADDRESS_WIDTH),
    .BURST_CAPABLE       (BURST_CAPABLE),
    .MAXIMUM_BURST_COUNT (MAXIMUM_BURST_COUNT),
    .BURST_COUNT_WIDTH   (BURST_COUNT_WIDTH)
) ddr3_read_0 (
    .clk                    (clk),                                     
    .reset_n                (reset_n),      		 //�͵�ƽ��λ         
    .soft_reset             (soft_reset),   		 //�ߵ�ƽ��λ
	//control�ӿ�
    .control_read_base      (control_read_base),      //����ַ
    .control_read_length    (control_read_length),    //������
    .control_fixed_location (),             
    .control_go             (control_go),            //��ʼд�ź�
    .control_done           (control_done),          //�����ź�
    .control_early_done     (control_early_done),    //������ź�
	//user�ӿ�
    .user_read_clk          (user_read_clk),    	 //��ʱ��    
    .user_read_buffer       (user_read_buffer), 	 //������      
    .user_buffer_data       (user_buffer_data),  	 //������   
    .user_data_available    (user_data_available),   //fifo�Ƿ��    
	//avalon_mm_master�ӿ�
    .master_address         (master_address),        
    .master_read            (master_read),          
    .master_byteenable      (master_byteenable),     
    .master_readdata        (master_readdata),      
    .master_readdatavalid   (master_readdatavalid),  //��������Ч�ź�
    .master_burstcount      (master_burstcount),     
    .master_waitrequest     (master_waitrequest)     
);

//ddr3_vga_ctrl
ddr3_vga_ctrl ddr3_vga_ctrl_0 (
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
	.control_user_base   (control_read_base),    
	.control_user_length (control_read_length),  
	.control_go          (hps_start_cap),  			//hpsдһ֡����
	.control_en          (master_ctrl_en),  		//Ԥ�����ƼĴ���
	.control_state       (buffer_status)            //����״̬
);

//vga_ctrl
vga_ctrl #(
    .USER_DATA_WIDTH     (USER_DATA_WIDTH)
)
vga_ctrl_inst(
    .clk             (clk_5M     ),  //ʱ���ź�
    .sys_rst_n       (reset_n   ),  //��λ�ź�
	//vgaʱ�����
    .vga_clk         (vga_clk     ),  //����ͷ����ʱ��
    .vga_de          (vga_de    ),  //����ͷ��ͬ���ź�
    .vga_hsync       (vga_hsync   ),  //����ͷ��ͬ���ź�
    .vga_vsync       (vga_vsync    ),  //����ͷͼ������
    .vga_rgb         (vga_rgb),         //ͼ������
	//����
    .read_req        (read_req   ),     //������
    .read_data       (read_data   ),    //������
	//��ͬ������
    .cmos_vsync_begin   (cmos_vsync_begin   ),    //��ͬ����ʼ
    .cmos_vsync_end     (cmos_vsync_end   )    //��ͬ������
);


//=======================================================
//�����߼�
//=======================================================

//����߼���ֵ
assign user_read_clk=vga_clk;//��ʱ��Ϊvgaʱ��
assign user_read_buffer=read_req&en_cap;//�������ɶ������벶׽��Ч�źŹ�ͬ����
assign read_data=user_buffer_data;//�����ݸ�ֵ
assign soft_reset=master_ctrl_en[0];//��ʹ�������λ����ʱ���ã�
assign vga_done=control_early_done;
//vga_clk�µ�ʱ��

	//start_cap	
	always @(posedge vga_clk or negedge reset_n)
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
	always @(posedge vga_clk or negedge reset_n)
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
	always @(posedge vga_clk or negedge reset_n)
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
	always @(posedge vga_clk or negedge reset_n)
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

	//ʹ�ñ��ؼ���������ź������أ�ֻ�����һ��ʱ������(����vgaʱ�Ӽ��)
	always @(posedge clk or negedge reset_n)begin
			if(reset_n == 1'b0)begin
				D <= 2'b00;
			end
			else begin
				D <= {D[0], hps_start_cap};  	//D[1]��ʾǰһ״̬��D[0]��ʾ��һ״̬�������ݣ� 
			end
		end
	assign  pos_edge = ~D[1] & D[0];
		
	//ʹ�ñ��ؼ����done�ź������أ�ֻ�����һ��ʱ������(����vgaʱ�Ӽ��)
	always @(posedge clk or negedge reset_n)begin
			if(reset_n == 1'b0)begin
				D1 <= 2'b00;
			end
			else begin
				D1 <= {D1[0], control_early_done};  	//D[1]��ʾǰһ״̬��D[0]��ʾ��һ״̬�������ݣ� 
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
			
			
//������������singaltapץȡ
			
//����һ��de�ź�
reg [1:0]D2;
wire de_edge;
always @(posedge vga_clk or negedge reset_n)begin
    if(reset_n == 1'b0)begin
        D2 <= 2'b00;
    end
    else begin
        D2 <= {D2[0], vga_vsync};  	//D[1]��ʾǰһ״̬��D[0]��ʾ��һ״̬�������ݣ� 
    end
    end
assign  de_edge = ~D2[1] & D2[0];

reg  flag1;//��¼��һ��vga_de
always @(posedge vga_clk or negedge reset_n)
    if(reset_n == 1'b0)
        flag1 <= 1'b0;
    else if(de_edge==1)
        flag1 <= 1'b1;
    else if(vga_de==1)
        flag1 <= 1'b0;
    else
        flag1 <= flag1;
assign flag=flag1;


// //����control_go�ź�
// reg [1:0]D3;
// wire GO_edge;
// always @(posedge vga_clk or negedge reset_n)begin
    // if(reset_n == 1'b0)begin
        // D3 <= 2'b00;
    // end
    // else begin
        // D3 <= {D3[0], flag1};  	//D[1]��ʾǰһ״̬��D[0]��ʾ��һ״̬�������ݣ� 
    // end
    // end
// assign  GO_edge = D3[1] & ~D3[0];

// always @(posedge vga_clk or negedge reset_n)
	// if (reset_n == 1'b0)
		// control_go1  <= 1'd0;
	// else if (GO_edge==1)begin
			// control_go1  <= 1'd1;
	// end
	// else
		// control_go1  <= 1'd0;
// assign control_go=control_go1;



endmodule