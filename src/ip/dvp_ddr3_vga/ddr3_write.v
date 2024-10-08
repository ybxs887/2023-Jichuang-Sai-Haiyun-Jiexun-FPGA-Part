module ddr3_write
#(
//����
	parameter USER_DATA_WIDTH = 32,		//����λ��32
	parameter AVALON_DATA_WIDTH = 32,	//���λ��32
	parameter MEMORY_BASED_FIFO = 1,	//ʹ���ڲ�memory	
	parameter FIFO_DEPTH = 256,			//FIFO���Ϊ256=8192/32
	parameter FIFO_DEPTH_LOG2 = 8,		//FIFO��ȵ�λ��
	parameter ADDRESS_WIDTH = 32,		//��ַ�߿��
	parameter BURST_CAPABLE = 1,		//ʹ��ͻ��
	parameter MAXIMUM_BURST_COUNT = 16, //���ͻ������16
	parameter BURST_COUNT_WIDTH = 5		//ͻ������λ��+1
)
(
	clk,
	reset_n,//Ӳ���͵�ƽ���븴λ
	soft_reset,//�����λ,�ߵ�ƽ��Ч
	//control���ƽӿ�
	control_fixed_location,
	control_write_base,
	control_write_length,
	control_go,
	control_done,
	//user�ӿ�
	user_write_clk,
	user_write_buffer,
	user_buffer_data,
	user_buffer_full,
	//avalon_mm_master�ӿ�
	master_address,
	master_write,
	master_byteenable,
	master_writedata,
	master_burstcount,
	master_waitrequest
);
//�����������

	input								clk;
	input								reset_n;
	input								soft_reset;
	//control���ƽӿ�
	input								control_fixed_location;
	input	[ADDRESS_WIDTH-1:0]			control_write_base;			// for write master
	input	[ADDRESS_WIDTH-1:0]			control_write_length;		// for write master
	input								control_go;
	output wire							control_done;	
	//user�ӿ�
	input								user_write_buffer;			// for write master
	input								user_write_clk;	
	input	[USER_DATA_WIDTH-1:0]		user_buffer_data;		// for write master
	output wire							user_buffer_full;			// for write master
	
	//avalon_mm_master�ӿ�
	output wire	[ADDRESS_WIDTH-1:0]			master_address;
	output wire								master_write;				// for write master
	output wire	[(AVALON_DATA_WIDTH/8)-1:0]	master_byteenable;
	output wire	[AVALON_DATA_WIDTH-1:0]		master_writedata;			// for write master
	output wire	[BURST_COUNT_WIDTH-1:0]		master_burstcount;			// for bursting read and write masters
	input									master_waitrequest;
	
//��ֵ
	assign reset= soft_reset||(~reset_n);
	
//����д����
	generate
		if(BURST_CAPABLE == 1) begin
			burst_write_master a_burst_write_master(
				.clk                    (clk),
				.reset                  (reset),//�ߵ�ƽ��λ
				
				.control_fixed_location (control_fixed_location),
				.control_write_base     (control_write_base),
				.control_write_length   (control_write_length),
				.control_go             (control_go),
				.control_done           (control_done),
				
				.user_write_clk 		(user_write_clk),
				.user_write_buffer      (user_write_buffer),
				.user_buffer_data       (user_buffer_data),
				.user_buffer_full       (user_buffer_full),
				
				.master_address         (master_address),
				.master_write           (master_write),
				.master_byteenable      (master_byteenable),
				.master_writedata       (master_writedata),
				.master_burstcount      (master_burstcount),
				.master_waitrequest     (master_waitrequest)
			);
			defparam a_burst_write_master.USER_DATAWIDTH = USER_DATA_WIDTH;
			defparam a_burst_write_master.AVALON_DATAWIDTH = AVALON_DATA_WIDTH;
			defparam a_burst_write_master.MAXBURSTCOUNT = MAXIMUM_BURST_COUNT;
			defparam a_burst_write_master.BURSTCOUNTWIDTH = BURST_COUNT_WIDTH;
			defparam a_burst_write_master.BYTEENABLEWIDTH = AVALON_DATA_WIDTH/8;
			defparam a_burst_write_master.ADDRESSWIDTH = ADDRESS_WIDTH;
			defparam a_burst_write_master.FIFODEPTH = FIFO_DEPTH;
			defparam a_burst_write_master.FIFODEPTH_LOG2 = FIFO_DEPTH_LOG2;
			defparam a_burst_write_master.FIFOUSEMEMORY = MEMORY_BASED_FIFO;
		end
		else begin
			write_master a_write_master(
				.clk                    (clk),
				.reset                  (reset),//�ߵ�ƽ��λ
				
				.control_fixed_location (control_fixed_location),
				.control_write_base     (control_write_base),
				.control_write_length   (control_write_length),
				.control_go             (control_go),
				.control_done           (control_done),
				
				.user_write_clk 		(user_write_clk),
				.user_write_buffer      (user_write_buffer),
				.user_buffer_data       (user_buffer_data),
				.user_buffer_full       (user_buffer_full),
				
				.master_address         (master_address),
				.master_write           (master_write),
				.master_byteenable      (master_byteenable),
				.master_writedata       (master_writedata),
				.master_waitrequest     (master_waitrequest)
			);
			defparam a_write_master.USER_DATAWIDTH = USER_DATA_WIDTH;
			defparam a_write_master.AVALON_DATAWIDTH = AVALON_DATA_WIDTH;
			defparam a_write_master.BYTEENABLEWIDTH = AVALON_DATA_WIDTH/8;
			defparam a_write_master.ADDRESSWIDTH = ADDRESS_WIDTH;
			defparam a_write_master.FIFODEPTH = FIFO_DEPTH;
			defparam a_write_master.FIFODEPTH_LOG2 = FIFO_DEPTH_LOG2;
			defparam a_write_master.FIFOUSEMEMORY = MEMORY_BASED_FIFO;
		end
	endgenerate
endmodule