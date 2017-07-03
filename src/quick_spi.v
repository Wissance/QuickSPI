`timescale 1ns / 1ps

module quick_spi #(
    parameter INCOMING_DATA_WIDTH = 8,
    parameter OUTGOING_DATA_WIDTH = 16,
    parameter NUMBER_OF_SLAVES = 2)
(
    input wire clk,
    input wire reset_n,
    input wire start_transaction,
    input wire[NUMBER_OF_SLAVES-1:0] slave,
    input wire[OUTGOING_DATA_WIDTH-1:0] outgoing_data,
    output reg mosi,
    input wire miso,
    output reg sclk,
    output reg[NUMBER_OF_SLAVES-1:0] ss_n);

reg[31:0] sclk_toggle_count;
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
reg [7:0] num_toggles_to_wait;

reg[INCOMING_DATA_WIDTH-1:0] incoming_data_buffer;

reg[7:0] memory [0: 255];

wire[7:0] CPOL = memory[0];
wire[7:0] CPHA = memory[1];

wire[7:0] outgoing_element_size = memory[2];
wire[7:0] num_outgoing_elements = memory[3];
wire[7:0] incoming_element_size = memory[4];

wire[7:0] num_write_extra_toggles = memory[5];
wire[7:0] num_read_extra_toggles = memory[6];

reg[7:0] num_bits_read;
reg[7:0] num_bits_written;
reg[7:0] num_elements_written;

reg[3:0] incoming_byte_bit;
reg[3:0] outgoing_byte_bit;

reg[7:0] num_bytes_read;
reg[7:0] num_bytes_written;

reg[7:0] read_buffer_start;
reg[7:0] write_buffer_start;

reg burst;
reg enable_read;
reg[31:0] extra_toggle_count;

always @ (posedge clk) begin
    if(!reset_n) begin
        memory[0] <= /*CPOL*/ 0;
        memory[1] <= /*CPHA*/ 0;
        memory[2] <= /*outgoing_element_size*/ 16;
        memory[3] <= /*num_outgoing_elements*/ 1;
		memory[4] <= /*incoming_element_size*/ 9;
		memory[5] <= /*num_write_extra_toggles*/3;
		memory[6] <= /*num_read_extra_toggles*/2;
		
		num_elements_written <= 0;
		num_bits_read <= 0;
        num_bits_written <= 0;
		
		incoming_byte_bit <= 0;
		outgoing_byte_bit <= 0;
		
		num_bytes_read <= 0;
		num_bytes_written <= 0;
		
		read_buffer_start <= 30;
		write_buffer_start <= 7;
		
		burst <= 1'b0;
		enable_read <= 1'b0;
		extra_toggle_count <= 0;
		wait_after_read <= 1'b0;
    
        mosi <= 1'bz;
        sclk <= /*CPOL;*/0;
        ss_n <= {NUMBER_OF_SLAVES{1'b1}};
        sclk_toggle_count <= 0;
        spi_clock_phase <= /*CPHA;*/0;
        sm1_state <= SM1_IDLE;
    end
    
    else begin
        case(sm1_state)
            SM1_IDLE: begin
				if(start_transaction) begin
                    memory[7] <= outgoing_data[15:8];
                    memory[8] <= outgoing_data[7:0];
				
					sm1_state <= SM1_SELECT_SLAVE;
					sm2_state <= SM2_WRITE;
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
                            if(num_outgoing_elements == 1)
                                sm2_state <= SM2_WAIT;
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
										sm2_state <= SM2_WAIT;
									end
									
									else
										num_bits_written <= 0;
								end
								
								else
									sm2_state <= SM2_WAIT;
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
								sm2_state <= SM2_WAIT;
							end
						end
                    end
					
					SM2_WAIT: begin
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
							
						extra_toggle_count <= extra_toggle_count + 1;
					end
					
					SM2_END_DATA_TRANSFER: begin
						spi_clock_phase <= CPHA;
						sclk_toggle_count <= 0;
						ss_n[slave] <= 1'b1;
						mosi <= 1'bz;
						
						num_bits_read <= 0;
						num_bits_written <= 0;
						
						if(num_elements_written == num_outgoing_elements)
							sm1_state <= SM1_IDLE;
						else
							sm1_state <= SM1_SELECT_SLAVE;
					end
                endcase
            end
        endcase
    end
end
endmodule
