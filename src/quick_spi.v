`timescale 1 ns / 1 ps

module quick_spi #
(
    parameter integer C_S_AXI_ID_WIDTH = 1,
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 8,
    parameter integer C_S_AXI_AWUSER_WIDTH = 0,
    parameter integer C_S_AXI_ARUSER_WIDTH = 0,
    parameter integer C_S_AXI_WUSER_WIDTH = 0,
    parameter integer C_S_AXI_RUSER_WIDTH = 0,
    parameter integer C_S_AXI_BUSER_WIDTH = 0,
/********************************************************/
    parameter integer MEMORY_SIZE = 64,
    parameter integer NUMBER_OF_SLAVES = 2
)
(
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    input wire [C_S_AXI_ID_WIDTH-1:0] s_axi_awid,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input wire [7:0] s_axi_awlen,
    input wire [2:0] s_axi_awsize,
    input wire [1:0] s_axi_awburst,
    input wire s_axi_awlock,
    input wire [3:0] s_axi_awcache,
    input wire [2:0] s_axi_awprot,
    input wire [3:0] s_axi_awqos,
    input wire [3:0] s_axi_awregion,
    input wire [C_S_AXI_AWUSER_WIDTH-1:0] s_axi_awuser,
    input wire s_axi_awvalid,
    output wire s_axi_awready,
    input wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input wire s_axi_wlast,
    input wire [C_S_AXI_WUSER_WIDTH-1:0] s_axi_wuser,
    input wire s_axi_wvalid,
    output wire s_axi_wready,
    output wire [C_S_AXI_ID_WIDTH-1:0] s_axi_bid,
    output wire [1:0] s_axi_bresp,
    output wire [C_S_AXI_BUSER_WIDTH-1:0] s_axi_buser,
    output wire s_axi_bvalid,
    input wire s_axi_bready,
    input wire [C_S_AXI_ID_WIDTH-1:0] s_axi_arid,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input wire [7:0] s_axi_arlen,
    input wire [2:0] s_axi_arsize,
    input wire [1:0] s_axi_arburst,
    input wire s_axi_arlock,
    input wire [3:0] s_axi_arcache,
    input wire [2:0] s_axi_arprot,
    input wire [3:0] s_axi_arqos,
    input wire [3:0] s_axi_arregion,
    input wire [C_S_AXI_ARUSER_WIDTH-1:0] s_axi_aruser,
    input wire s_axi_arvalid,
    output wire s_axi_arready,
    output wire [C_S_AXI_ID_WIDTH-1:0] s_axi_rid,
    output wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output wire [1:0] s_axi_rresp,
    output wire s_axi_rlast,
    output wire [C_S_AXI_RUSER_WIDTH-1:0] s_axi_ruser,
    output wire s_axi_rvalid,
    input wire s_axi_rready,
/********************************************************/
    output reg mosi,
    input wire miso,
    output reg sclk,
    output reg[NUMBER_OF_SLAVES-1:0] ss_n
);

reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
reg axi_awready;
reg axi_wready;
reg [1:0] axi_bresp;
reg [C_S_AXI_BUSER_WIDTH-1:0] axi_buser;
reg axi_bvalid;
reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
reg axi_arready;
reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
reg [1:0] axi_rresp;
reg axi_rlast;
reg [C_S_AXI_RUSER_WIDTH-1:0] axi_ruser;
reg axi_rvalid;

wire aw_wrap_en;
wire ar_wrap_en;
wire [31:0] aw_wrap_size;
wire [31:0] ar_wrap_size;
reg axi_awv_awr_flag;
reg axi_arv_arr_flag; 

reg [7:0] axi_awlen_cntr;
reg [7:0] axi_arlen_cntr;
reg [1:0] axi_arburst;
reg [1:0] axi_awburst;
reg [7:0] axi_arlen;
reg [7:0] axi_awlen;

localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32)+ 1;
localparam integer OPT_MEM_ADDR_BITS = 3;

wire [OPT_MEM_ADDR_BITS:0] memory_address;
reg [C_S_AXI_DATA_WIDTH-1:0] outgoing_data;

assign s_axi_awready = axi_awready;
assign s_axi_wready	= axi_wready;
assign s_axi_bresp = axi_bresp;
assign s_axi_buser = axi_buser;
assign s_axi_bvalid	= axi_bvalid;
assign s_axi_arready = axi_arready;
assign s_axi_rdata = axi_rdata;
assign s_axi_rresp = axi_rresp;
assign s_axi_rlast = axi_rlast;
assign s_axi_ruser = axi_ruser;
assign s_axi_rvalid	= axi_rvalid;
assign s_axi_bid = s_axi_awid;
assign s_axi_rid = s_axi_arid;
assign aw_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_awlen)); 
assign ar_wrap_size = (C_S_AXI_DATA_WIDTH/8 * (axi_arlen)); 
assign aw_wrap_en = ((axi_awaddr & aw_wrap_size) == aw_wrap_size)? 1'b1: 1'b0;
assign ar_wrap_en = ((axi_araddr & ar_wrap_size) == ar_wrap_size)? 1'b1: 1'b0;
assign s_axi_buser = 0;

/*****************************************************************************************/

reg[15:0] sclk_toggle_count;
reg spi_clock_phase;

localparam SM1_IDLE = 2'b00;
localparam SM1_SELECT_SLAVE = 2'b01;
localparam SM1_TRANSFER_DATA = 2'b10;
reg[1:0] sm1_state;

localparam SM2_WRITE = 2'b00;
localparam SM2_READ = 2'b01;
localparam SM2_WAIT = 2'b10;
localparam SM2_END_DATA_TRANSFER = 2'b11;
reg[1:0] sm2_state;

reg wait_after_read;
reg[15:0] num_toggles_to_wait;
reg [8-1:0] memory [0:MEMORY_SIZE-1];

wire CPOL = memory[0][0];
wire CPHA = memory[0][1];
wire start = memory[0][2];
wire burst = memory[0][3];
wire slave = memory[1];
wire enable_read = memory[0][4];

wire[15:0] outgoing_element_size = {memory[2], memory[3]};
wire[15:0] num_outgoing_elements = {memory[4], memory[5]};
wire[15:0] incoming_element_size = {memory[6], memory[7]};
wire[15:0] num_write_extra_toggles = {memory[8], memory[9]};
wire[15:0] num_read_extra_toggles = {memory[10], memory[11]};

reg[15:0] num_bits_read;
reg[15:0] num_bits_written;
reg[15:0] num_elements_written;
reg[3:0] incoming_byte_bit;
reg[3:0] outgoing_byte_bit;
reg[15:0] num_bytes_read;
reg[15:0] num_bytes_written;

localparam write_buffer_start = 12;
localparam read_buffer_start = 38; /* (MEMORY_SIZE - write_buffer_start) / 2; */
localparam num_initial_axi_transfer_bytes = read_buffer_start;

reg[15:0] extra_toggle_count;

/*****************************************************************************************/

always @(posedge s_axi_aclk) begin
	if (s_axi_aresetn == 1'b0) begin
		axi_awready <= 1'b0;
		axi_awv_awr_flag <= 1'b0;
	end
	
	else begin    
		if (~axi_awready && s_axi_awvalid && ~axi_awv_awr_flag && ~axi_arv_arr_flag) begin
			axi_awready <= 1'b1;
			axi_awv_awr_flag  <= 1'b1; 
		end
		
		else if (s_axi_wlast && axi_wready) begin
			axi_awv_awr_flag  <= 1'b0;
		end
		
		else begin
			axi_awready <= 1'b0;
		end
	end 
end       

always @(posedge s_axi_aclk) begin
	if (s_axi_aresetn == 1'b0) begin
		axi_awaddr <= 0;
		axi_awlen_cntr <= 0;
		axi_awburst <= 0;
		axi_awlen <= 0;
	end
	
	else begin
		if (~axi_awready && s_axi_awvalid && ~axi_awv_awr_flag) begin
			axi_awaddr <= s_axi_awaddr[C_S_AXI_ADDR_WIDTH-1:0];  
			axi_awburst <= s_axi_awburst; 
			axi_awlen <= s_axi_awlen;     
			axi_awlen_cntr <= 0;
		end
		
		else if((axi_awlen_cntr <= axi_awlen) && axi_wready && s_axi_wvalid) begin
			axi_awlen_cntr <= axi_awlen_cntr + 1;

			case (axi_awburst)
				2'b00: begin
					axi_awaddr <= axi_awaddr;          
				end
				
				2'b01: begin
					axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
					axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
				end
				
				2'b10:
					if (aw_wrap_en) begin
						axi_awaddr <= (axi_awaddr - aw_wrap_size); 
					end
					
					else begin
						axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
						axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}}; 
					end
					
				default: begin
					axi_awaddr <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
				end
			endcase              
		end
	end 
end       

always @(posedge s_axi_aclk) begin
	if (s_axi_aresetn == 1'b0) begin
		axi_wready <= 1'b0;
	end
	
	else begin    
		if (~axi_wready && s_axi_wvalid && axi_awv_awr_flag) begin
			axi_wready <= 1'b1;
		end
		//else if (~axi_awv_awr_flag)
		else if (s_axi_wlast && axi_wready) begin
			axi_wready <= 1'b0;
		end
	end 
end       

always @(posedge s_axi_aclk) begin
	if (s_axi_aresetn == 1'b0) begin
		axi_bvalid <= 0;
		axi_bresp <= 2'b0;
	end

	else begin    
		if (axi_awv_awr_flag && axi_wready && s_axi_wvalid && ~axi_bvalid && s_axi_wlast) begin
			axi_bvalid <= 1'b1;
			axi_bresp  <= 2'b0; 
		end
		
		else begin
			if (s_axi_bready && axi_bvalid) begin
				axi_bvalid <= 1'b0; 
			end  
		end
	end
 end   

always @(posedge s_axi_aclk) begin
	if (s_axi_aresetn == 1'b0) begin
		axi_arready <= 1'b0;
		axi_arv_arr_flag <= 1'b0;
	end
	
	else begin    
		if (~axi_arready && s_axi_arvalid && ~axi_awv_awr_flag && ~axi_arv_arr_flag) begin
			axi_arready <= 1'b1;
			axi_arv_arr_flag <= 1'b1;
		end
		
		else if (axi_rvalid && s_axi_rready && axi_arlen_cntr == axi_arlen) begin
			axi_arv_arr_flag  <= 1'b0;
		end

		else begin
			axi_arready <= 1'b0;
		end
	end 
end       

always @(posedge s_axi_aclk) begin
	if (s_axi_aresetn == 1'b0) begin
		axi_araddr <= 0;
		axi_arlen_cntr <= 0;
		axi_arburst <= 0;
		axi_arlen <= 0;
		axi_rlast <= 1'b0;
	end
	
	else begin    
		if (~axi_arready && s_axi_arvalid && ~axi_arv_arr_flag) begin
			axi_araddr <= s_axi_araddr[C_S_AXI_ADDR_WIDTH - 1:0]; 
			axi_arburst <= s_axi_arburst; 
			axi_arlen <= s_axi_arlen;     
			axi_arlen_cntr <= 0;
			axi_rlast <= 1'b0;
		end
		
		else if((axi_arlen_cntr <= axi_arlen) && axi_rvalid && s_axi_rready) begin
			axi_arlen_cntr <= axi_arlen_cntr + 1;
			axi_rlast <= 1'b0;
		
			case (axi_arburst)
				2'b00: begin
					axi_araddr <= axi_araddr;        
				end
				
				2'b01: begin
					axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
					axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
				end
				
				2'b10:
					if (ar_wrap_en) begin
						axi_araddr <= (axi_araddr - ar_wrap_size); 
					end
					
					else begin
						axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
						axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
					end
				default: begin
					axi_araddr <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB]+1;
				end
			endcase       
		end

		else if((axi_arlen_cntr == axi_arlen) && ~axi_rlast && axi_arv_arr_flag) begin
			axi_rlast <= 1'b1;
		end
		
		else if (s_axi_rready) begin
			axi_rlast <= 1'b0;
		end          
	end
end

always @(posedge s_axi_aclk) begin
	if (s_axi_aresetn == 1'b0) begin
	  axi_rvalid <= 0;
	  axi_rresp  <= 0;     
	end
	
	else begin    
		if (axi_arv_arr_flag && ~axi_rvalid) begin
			axi_rvalid <= 1'b1;
			axi_rresp  <= 2'b0;
		end
		
		else if (axi_rvalid && s_axi_rready) begin
			axi_rvalid <= 1'b0;
		end            
	end
end    

assign memory_address =
	(axi_arv_arr_flag ?
	axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] :
	(axi_awv_awr_flag? axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB]:0));
	
wire memory_write_enable = axi_wready && s_axi_wvalid;
wire memory_read_enable = axi_arv_arr_flag; //& ~axi_rvalid

integer num_initial_axi_transfer_bytes_received_wstrb_0;
integer num_initial_axi_transfer_bytes_received_wstrb_1;
integer num_initial_axi_transfer_bytes_received_wstrb_2;
integer num_initial_axi_transfer_bytes_received_wstrb_3;
integer i;

always @(posedge s_axi_aclk) begin
    if (s_axi_aresetn == 1'b0) begin
        num_initial_axi_transfer_bytes_received_wstrb_0 <= 0;
        num_initial_axi_transfer_bytes_received_wstrb_1 <= 0;
        num_initial_axi_transfer_bytes_received_wstrb_2 <= 0;
        num_initial_axi_transfer_bytes_received_wstrb_3 <= 0;
        
        for (i = 0; i < MEMORY_SIZE - 1; i = i + 1)
            memory[i] <= 0;
        
        num_elements_written <= 0;
        num_bits_read <= 0;
        num_bits_written <= 0;
        
        incoming_byte_bit <= 0;
        outgoing_byte_bit <= 0;
        
        num_bytes_read <= 0;
        num_bytes_written <= 0;
        
        extra_toggle_count <= 0;
        wait_after_read <= 1'b0;
        
        mosi <= 1'bz;
        sclk <= 0;
        ss_n <= {NUMBER_OF_SLAVES{1'b1}};
        sclk_toggle_count <= 0;
        spi_clock_phase <= 0;
        
        sm1_state <= SM1_IDLE;
        sm2_state <= SM2_WRITE;
    end

	else begin
		if(memory_write_enable) begin
			if (s_axi_wstrb[0]) begin
				memory[(memory_address*4) + 0] <= s_axi_wdata[(0*8+7) -: 8];
				num_initial_axi_transfer_bytes_received_wstrb_0 <= num_initial_axi_transfer_bytes_received_wstrb_0 + 1;
            end
				
			if (s_axi_wstrb[1]) begin
				memory[(memory_address*4) + 1] <= s_axi_wdata[(1*8+7) -: 8];
				num_initial_axi_transfer_bytes_received_wstrb_1 <= num_initial_axi_transfer_bytes_received_wstrb_1 + 1;
            end
				
			if (s_axi_wstrb[2]) begin
				memory[(memory_address*4) + 2] <= s_axi_wdata[(2*8+7) -: 8];
				num_initial_axi_transfer_bytes_received_wstrb_2 <= num_initial_axi_transfer_bytes_received_wstrb_2 + 1;
            end
				
			if (s_axi_wstrb[3]) begin
				memory[(memory_address*4) + 3] <= s_axi_wdata[(3*8+7) -: 8];
				num_initial_axi_transfer_bytes_received_wstrb_3 <= num_initial_axi_transfer_bytes_received_wstrb_3 + 1;
            end
		end
        
        else begin
		    if((num_initial_axi_transfer_bytes_received_wstrb_0 +
                num_initial_axi_transfer_bytes_received_wstrb_1 +
                num_initial_axi_transfer_bytes_received_wstrb_2 +
                num_initial_axi_transfer_bytes_received_wstrb_3) == num_initial_axi_transfer_bytes) begin
				case(sm1_state)
					SM1_IDLE: begin
						if(start) begin
							sclk <= CPOL;
							spi_clock_phase <= CPHA;
							
							sm1_state <= SM1_SELECT_SLAVE;
						end
					end
					
					SM1_SELECT_SLAVE: begin
						ss_n[slave] <= 1'b0;
						
						if(!CPHA) begin
							outgoing_byte_bit <= outgoing_byte_bit + 1;
							mosi <= memory[write_buffer_start + num_bytes_written][outgoing_byte_bit];
							num_bits_written <= num_bits_written + 1;
							
							if(outgoing_element_size == 1) begin
								num_elements_written <= 1;
								
								if(enable_read)
									sm2_state <= SM2_READ;
								else begin
									if(num_outgoing_elements == 1) begin
										if(!num_write_extra_toggles)
											sm2_state <= SM2_END_DATA_TRANSFER;
										else
											sm2_state <= SM2_WAIT;
									end
									
									else
										sm2_state <= SM2_WRITE;
								end
							end
							
							else
								sm2_state <= SM2_WRITE;
						end
						
						sm1_state <= SM1_TRANSFER_DATA;
					end
					
					SM1_TRANSFER_DATA: begin
						sclk <= ~sclk;
						spi_clock_phase <= ~spi_clock_phase;
						sclk_toggle_count <= sclk_toggle_count + 1;
						
						case(sm2_state)
							SM2_WRITE: begin
								if(!spi_clock_phase) begin
									outgoing_byte_bit <= outgoing_byte_bit + 1;
									
									if(outgoing_byte_bit == 7) begin
										num_bytes_written <= num_bytes_written + 1;
										outgoing_byte_bit <= 0;
									end
											
									mosi <= memory[write_buffer_start + num_bytes_written][outgoing_byte_bit];
									num_bits_written <= num_bits_written + 1;
									
									if(num_bits_written == outgoing_element_size - 1) begin
										num_elements_written <= num_elements_written + 1;
										
										if(burst) begin
											if(num_elements_written == num_outgoing_elements - 1) begin
												if(!num_write_extra_toggles)
													sm2_state <= SM2_END_DATA_TRANSFER;
												else
													sm2_state <= SM2_WAIT;
											end
											
											else
												num_bits_written <= 0;
										end
										
										else begin
											if(!num_write_extra_toggles)
												sm2_state <= SM2_END_DATA_TRANSFER;
											else
												sm2_state <= SM2_WAIT;
										end
									end
								end
							end
							
							SM2_READ: begin
								if(spi_clock_phase) begin
									incoming_byte_bit <= incoming_byte_bit + 1;
								
									if(incoming_byte_bit == 7) begin
										num_bytes_read <= num_bytes_read + 1;
										incoming_byte_bit <= 0;
									end
																
									memory[read_buffer_start + num_bytes_read][incoming_byte_bit] <= miso;
									num_bits_read <= num_bits_read + 1;
									
									if(num_bits_read == incoming_element_size - 1) begin
										wait_after_read <= 1'b1;
										
										if(!num_read_extra_toggles)
											sm2_state <= SM2_END_DATA_TRANSFER;
										else
											sm2_state <= SM2_WAIT;
									end
								end
							end
							
							SM2_WAIT: begin
							   extra_toggle_count <= extra_toggle_count + 1;
							
								if(wait_after_read) begin
									if(extra_toggle_count == (num_read_extra_toggles - 1)) begin
										extra_toggle_count <= 0;
										sm2_state <= SM2_END_DATA_TRANSFER;
									end
								end
								
								else begin
									if(extra_toggle_count == (num_write_extra_toggles - 1)) begin
										extra_toggle_count <= 0;
										
										if(enable_read)
											sm2_state <= SM2_READ;
										else
											sm2_state <= SM2_END_DATA_TRANSFER;
									end
								end
							end
							
							SM2_END_DATA_TRANSFER: begin
								sclk <= CPOL;
								spi_clock_phase <= CPHA;
								sclk_toggle_count <= 0;
								ss_n[slave] <= 1'b1;
								mosi <= 1'bz;
								
								num_bits_read <= 0;
								num_bits_written <= 0;
								
								if(num_elements_written == num_outgoing_elements) begin
                                    num_initial_axi_transfer_bytes_received_wstrb_0 <= 0;
                                    num_initial_axi_transfer_bytes_received_wstrb_1 <= 0;
                                    num_initial_axi_transfer_bytes_received_wstrb_2 <= 0;
                                    num_initial_axi_transfer_bytes_received_wstrb_3 <= 0;
									/* start */
									memory[0][2] <= 1'b0;
								
									num_elements_written <= 0;
									num_bytes_written <= 0;
									sm1_state <= SM1_IDLE;
								end
								
								else
									sm1_state <= SM1_SELECT_SLAVE;
							end
						endcase
					end
				endcase
			end
        end
    end
end

always @(posedge s_axi_aclk) begin
	if (memory_read_enable) begin
		outgoing_data[(0*8+7) -: 8] <= memory[(memory_address*4) + 0];
		outgoing_data[(1*8+7) -: 8] <= memory[(memory_address*4) + 1];
		outgoing_data[(2*8+7) -: 8] <= memory[(memory_address*4) + 2];
		outgoing_data[(3*8+7) -: 8] <= memory[(memory_address*4) + 3];
	end
end

always @(outgoing_data, axi_rvalid) begin
	if (axi_rvalid) begin
		axi_rdata <= outgoing_data;
	end
	
	else begin
		axi_rdata <= 32'h00000000;
	end       
end   

endmodule
