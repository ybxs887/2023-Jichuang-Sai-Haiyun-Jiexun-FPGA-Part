module  vga_ctrl
#(
//����
	parameter USER_DATA_WIDTH = 128		//����λ��
)
(
    input   wire            clk    		,   //���빤��ʱ��,Ƶ��5MHz
    input   wire            sys_rst_n   ,   //���븴λ�ź�,�͵�ƽ��Ч
	//vgaʱ�����
    output  wire           	vga_clk     ,   //���vgaʱ��,Ƶ��5MHz
    output   wire           vga_de    	,   //��Ч����ѡͨ�ź�DE
    output  wire            vga_hsync   ,   //�����ͬ���ź�
    output  wire            vga_vsync   ,   //�����ͬ���ź�
    output  wire    [23:0]  vga_rgb     ,   //���24bit������Ϣ
	//������
	output  wire            read_req	,   			//���������ź�
	input   wire    [USER_DATA_WIDTH-1:0]  read_data,   	//������
	// ��ͬ����ʼ�볡ͬ��������־
    output  wire            cmos_vsync_begin,   //��ͬ����ʼ
    output  wire            cmos_vsync_end     //��ͬ������
);

//=======================================================
//��������
//=======================================================

parameter H_SYNC    =    10'd40  ,   //��ͬ��
          H_BACK    =    10'd0   ,   //��ʱ�����
          H_VALID   =    10'd400 ,   //����Ч����
          H_FRONT   =    10'd0   ,   //��ʱ��ǰ��
          H_TOTAL   =    10'd440 ;   //��ɨ������
parameter V_SYNC    =  10'd40   ,   //��ͬ��
          V_BACK    =  10'd20  ,   //��ʱ�����
          V_VALID   =  10'd320 ,   //����Ч����
          V_FRONT   =  10'd0   ,   //��ʱ��ǰ��
          V_TOTAL   =  10'd380 ;   //��ɨ������

//=======================================================
//�źŶ���
//=======================================================

//ͬ���źŲ���
reg     [9:0]   cnt_h           ;   //��ͬ���źż�����
reg     [9:0]   cnt_v           ;   //��ͬ���źż�����

//���ݲ���
reg    [USER_DATA_WIDTH-1:0]  data_reg1;   	//�ݴ�3��read_data
reg    [USER_DATA_WIDTH-1:0]  data_reg;   	//��λ���vga_rgb
reg    [7:0]  					data;   		//�Ĵ�vga_rgb
reg	   [7:0]                 	cnt;            //����ʱ�������ش���
reg            				    read_req1;	   //���������źŴ�һ��
reg            				    read_req2;	   //���������źŴ�һ��
wire            				pix_data_req;	   //���������źŴ�һ��
wire            				pix_data_req1;	   //���������źŴ�һ��

reg                             vga_vsync_dly;  //vga�����ͬ���źŴ���
//���ؼ��
reg [1:0]D;				//���ؼ��Ĵ���
wire neg_edge;			//��׽read_req1�ź��½���

//=======================================================
//vgaͬ���źŲ���
//=======================================================

//vga_vsync_dly:vga�����ͬ���źŴ���,���ڲ���cmos_vsync_begin
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        vga_vsync_dly    <=  1'b0;
    else
        vga_vsync_dly    <=  vga_vsync;
//cmos_vsync_begin:֡ͼ���־�ź�,ÿ����һ��,����ͬ���źŸߵ�ƽ��ʼ
//cmos_vsync_end:֡ͼ���־�ź�,ÿ����һ��,����ͬ���źŵ͵�ƽ��ʼ
assign  cmos_vsync_begin = ((vga_vsync_dly == 1'b1)&& (vga_vsync == 1'b0)) ? 1'b1 : 1'b0;
assign  cmos_vsync_end = ((vga_vsync_dly == 1'b0)&& (vga_vsync == 1'b1)) ? 1'b1 : 1'b0;


//cnt_h:��ͬ���źż�����
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_h   <=  10'd0   ;
    else    if(cnt_h == H_TOTAL - 1'd1)
        cnt_h   <=  10'd0   ;
    else
        cnt_h   <=  cnt_h + 1'd1   ;

//vga_hsync:��ͬ���ź�
assign  vga_hsync = (cnt_h  <=  H_SYNC - 1'd1) ? 1'b0 : 1'b1  ;

//cnt_v:��ͬ���źż�����
always@(posedge clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_v   <=  10'd0 ;
    else    if((cnt_v == V_TOTAL - 1'd1) &&  (cnt_h == H_TOTAL-1'd1))
        cnt_v   <=  10'd0 ;
    else    if(cnt_h == H_TOTAL - 1'd1)
        cnt_v   <=  cnt_v + 1'd1 ;
    else
        cnt_v   <=  cnt_v ;

//vga_vsync:��ͬ���ź�,�ߵ�ƽ������Ч
assign  vga_vsync = (cnt_v  <=  V_SYNC - 1'd1) ? 1'b0 : 1'b1  ;

//vga_de:VGA��Ч��ʾ����
assign  vga_de = (((cnt_h >= H_SYNC + H_BACK )
                    && (cnt_h < H_SYNC + H_BACK + H_VALID))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK  + V_VALID)))
                    ? 1'b1 : 1'b0;

//pix_data_req:���ص�ɫ����Ϣ�����ź�,��ǰvga_de�ź�����ʱ������
assign  pix_data_req = (((cnt_h >= H_SYNC + H_BACK - 4)
                    && (cnt_h < H_SYNC + H_BACK + H_VALID - 4))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK + V_VALID)))
                    ? 1'b1 : 1'b0;

//pix_data_req1:���ص�ɫ����Ϣ�����ź�,��ǰvga_de�ź�2��ʱ������,β���ӳ�һ����
assign  pix_data_req1 = (((cnt_h >= H_SYNC + H_BACK - 2)
                    && (cnt_h < H_SYNC + H_BACK + H_VALID - 1))
                    &&((cnt_v >= V_SYNC + V_BACK )
                    && (cnt_v < V_SYNC + V_BACK + V_VALID)))
                    ? 1'b1 : 1'b0;					
					
					
//delete_area:��������128������
wire            				delete_area;	   //��������128������
assign  delete_area = (((cnt_h >= H_SYNC + H_BACK + H_VALID-80)//16*6
                    && (cnt_h < H_SYNC + H_BACK + H_VALID))
                    &&((cnt_v >= V_SYNC + V_BACK-1 )
                    && (cnt_v <V_SYNC + V_BACK)))
                    ? 1'b1 : 1'b0;				
//=======================================================
//���ݲ���
//=======================================================

//����д����read_req�ź�
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n)
		cnt <= 8'b0;
	else if(cnt==15)//Ϊ15ʱ��cnt����һ��
		cnt <= 8'b0;
	else if(pix_data_req == 1'b1||delete_area== 1'b1)
		cnt <= cnt+1'b1;
	else 
		cnt <= cnt;
// assign	read_req=(pix_data_req == 1'b1&&(cnt<=5'd2))?1'b1:1'b0;
assign	read_req=((pix_data_req == 1'b1||delete_area== 1'b1)&&(cnt<8'd1))?1'b1:1'b0;

//д����read_req�źŴ�һ��
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n)
		read_req1 <= 1'b0;
	else 
		read_req1 <= read_req;

//д����read_req1�źŴ�һ��
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n)
		read_req2 <= 1'b0;
	else 
		read_req2 <= read_req1;

//data_reg1�źżĴ�
always@(posedge clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            data_reg1    <=  0;
        end
    else    if(pix_data_req == 1'b1)//�ڳ�ǰ��Ч��Χ��
        begin
            if(read_req1 == 1'b1)//д�����һ���ź���Ч
				data_reg1    <=  {read_data};
            else
                data_reg1    <=  data_reg1;
        end
    else
        begin
            data_reg1    <=  0;
            data_reg    <=  data_reg;
        end		
		
//data_reg��ֵ
always@(posedge clk or negedge sys_rst_n)
	if(!sys_rst_n) begin
		data_reg <= 0;
		data <= 0;
    end
	else if(read_req2==1) begin
		data <= data_reg[7:0];//�ڸ�ֵdata_regʱ����Ĵ����ڲ����
		data_reg <= data_reg1;
    end
	else if(pix_data_req1==1) begin
			data <= data_reg[7:0];
			data_reg <= {8'b0,data_reg[USER_DATA_WIDTH-1:8]};//��ǰ��ʹӺ����
		end
	else begin
		data <= 0;
		data_reg <= data_reg;
	end
		
//vga_rgb:������ص�ɫ����Ϣ
// assign  vga_rgb = (vga_de == 1'b1) ? {vga_B,vga_G,vga_R} : 24'b0 ;//����
// assign  vga_rgb = (vga_de == 1'b1) ? {data[7:0],data[7:0],data[7:0]} : 24'b0 ;//������
assign  vga_rgb = (vga_de == 1'b1) ? {data,data,data} : 24'b0 ;
assign  vga_clk = clk;

// //vgaʱ�����
wire [31:0]x;
wire [31:0]y;
assign x=(cnt_h>H_SYNC+H_BACK-1'b1)&&(cnt_h<H_SYNC+H_BACK+H_VALID)?(cnt_h-H_SYNC-H_BACK+1'b1):32'd0;//(1~800) screen x coordinate
assign y=(cnt_v>V_SYNC+V_BACK-1'b1)&&(cnt_v<V_SYNC+V_BACK+V_VALID)?(cnt_v-V_SYNC-V_BACK+1'b1):32'd0;//(1~600) screen y coordinate

//����ͼ������
reg [7:0]vga_R;
reg [7:0]vga_G;
reg [7:0]vga_B;
	always@(posedge clk or negedge sys_rst_n)begin
		if(!sys_rst_n)begin
		vga_R<=0;
		vga_G<=0;
		vga_B<=0;
		end
		else begin
			if(x==0)begin
				vga_R<=0;
				vga_G<=0;
				vga_B<=0;
			end
			else if(x<H_VALID/3)begin//��ɫ
				vga_R<=8'd255;
				vga_G<=8'd255;
				vga_B<=8'd0;
			end
			else if(x<H_VALID*2/3)begin//��ɫ
				vga_R<=8'd0;
				vga_G<=8'd255;
				vga_B<=8'd255;
			end
			else begin//��ɫ
				vga_R<=8'd0;
				vga_G<=8'd255;
				vga_B<=8'd0;
			end
		end
	end


endmodule
