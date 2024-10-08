module ddr3_read
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
	parameter BURST_COUNT_WIDTH = 5		//ͻ������λ��+1
)
(
	clk,
	reset_n,//Ӳ���͵�ƽ���븴λ
	soft_reset,//�����λ,�ߵ�ƽ��Ч
	//control���ƽӿ�
	control_fixed_location,
	control_read_base,
	control_read_length,
	control_go,
	control_done,
	control_early_done,
	//user�ӿ�
	user_read_clk,
	user_read_buffer,
	user_buffer_data,
	user_data_available,
	//avalon_mm_master�ӿ�
	master_address,
	master_read,
	master_byteenable,
	master_readdata,
	master_readdatavalid,
	master_burstcount,
	master_waitrequest
);

//�����������
	input								clk;
	input								reset_n;
	input								soft_reset;
	//control���ƽӿ�
	input								control_fixed_location;
	input	[ADDRESS_WIDTH-1:0]			control_read_base;
	input	[ADDRESS_WIDTH-1:0]			control_read_length;
	input								control_go;
	output wire							control_done;
	output wire							control_early_done;  // don't use this unless you know what you are doing, it's going to fire when the last read is posted, not when the last data returns!
	//user�ӿ�
	input								user_read_buffer;			// for write master
	input								user_read_clk;	
	output wire	[USER_DATA_WIDTH-1:0]	user_buffer_data;		// for write master
	output wire							user_data_available;			// for write master
	
	//avalon_mm_master�ӿ�
	output wire	[ADDRESS_WIDTH-1:0]			master_address;
	output wire								master_read;				// for write master
	output wire	[(AVALON_DATA_WIDTH/8)-1:0]	master_byteenable;
	input wire	[AVALON_DATA_WIDTH-1:0]		master_readdata;			// for write master
	input									master_readdatavalid;
	output wire	[BURST_COUNT_WIDTH-1:0]		master_burstcount;			// for bursting read and write masters
	input									master_waitrequest;
	
//��ֵ
	assign reset= soft_reset||(~reset_n);
	


//����������
	generate
		if(BURST_CAPABLE == 1) begin
			burst_read_master a_burst_read_master(
				.clk                    (clk),
				.reset                  (reset),//�ߵ�ƽ��λ
				
				.control_fixed_location (control_fixed_location),
				.control_read_base      (control_read_base),
				.control_read_length    (control_read_length),
				.control_go             (control_go),
				.control_done           (control_done),
				.control_early_done     (control_early_done),
				
				.user_read_clk			(user_read_clk),
				.user_read_buffer       (user_read_buffer),
				.user_buffer_data       (user_buffer_data),
				.user_data_available    (user_data_available),
				
				.master_address         (master_address),
				.master_read            (master_read),
				.master_byteenable      (master_byteenable),
				.master_readdata        (master_readdata),
				.master_readdatavalid   (master_readdatavalid),
				.master_burstcount      (master_burstcount),
				.master_waitrequest     (master_waitrequest)
			);
			defparam a_burst_read_master.DATAWIDTH = USER_DATA_WIDTH;
			defparam a_burst_read_master.MAXBURSTCOUNT = MAXIMUM_BURST_COUNT;
			defparam a_burst_read_master.BURSTCOUNTWIDTH = BURST_COUNT_WIDTH;
			defparam a_burst_read_master.BYTEENABLEWIDTH = AVALON_DATA_WIDTH/8;
			defparam a_burst_read_master.ADDRESSWIDTH = ADDRESS_WIDTH;
			defparam a_burst_read_master.FIFODEPTH = FIFO_DEPTH;
			defparam a_burst_read_master.FIFODEPTH_LOG2 = FIFO_DEPTH_LOG2;
			defparam a_burst_read_master.FIFOUSEMEMORY = MEMORY_BASED_FIFO;
		end
		else begin
			latency_aware_read_master a_latency_aware_read_master(
				.clk                    (clk),
				.reset                  (reset),
				
				.control_fixed_location (control_fixed_location),
				.control_read_base      (control_read_base),
				.control_read_length    (control_read_length),
				.control_go             (control_go),
				.control_done           (control_done),
				.control_early_done     (control_early_done),
				
				.user_read_clk			(user_read_clk),
				.user_read_buffer       (user_read_buffer),
				.user_buffer_data       (user_buffer_data),
				.user_data_available    (user_data_available),
				
				.master_address         (master_address),
				.master_read            (master_read),
				.master_byteenable      (master_byteenable),
				.master_readdata        (master_readdata),
				.master_readdatavalid   (master_readdatavalid),
				.master_waitrequest     (master_waitrequest)
			);
			defparam a_latency_aware_read_master.USER_DATAWIDTH = USER_DATA_WIDTH;
			defparam a_latency_aware_read_master.AVALON_DATAWIDTH = AVALON_DATA_WIDTH;
			defparam a_latency_aware_read_master.BYTEENABLEWIDTH = AVALON_DATA_WIDTH/8;
			defparam a_latency_aware_read_master.ADDRESSWIDTH = ADDRESS_WIDTH;
			defparam a_latency_aware_read_master.FIFODEPTH = FIFO_DEPTH;
			defparam a_latency_aware_read_master.FIFODEPTH_LOG2 = FIFO_DEPTH_LOG2;
			defparam a_latency_aware_read_master.FIFOUSEMEMORY = MEMORY_BASED_FIFO;
		end
	endgenerate
endmodule 


