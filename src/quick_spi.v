`timescale 1ns / 1ps

module quick_spi #(parameter NUMBER_OF_SLAVES = 2)
(
    input wire clk,
    input wire reset_n,
    output reg mosi,
    input wire miso,
    output reg sclk,
    output reg[NUMBER_OF_SLAVES-1:0] ss_n);

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
reg[7:0] memory [0: 255];

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

localparam read_buffer_start = 30;
localparam write_buffer_start = 12;

reg[15:0] extra_toggle_count;

always @ (posedge clk) begin
    if(!reset_n) begin
        /*CPOL*/
        memory[0][0] <= 1'b0;
        /*CPHA*/
        memory[0][1] <= 1'b0;
        /* start */
        memory[0][2] <= 1'b1;
        /* burst */
        memory[0][3] <= 1'b1;
        /* enable_read */
        memory[0][4] <= 1'b0;
        /* slave */
        memory[1] <= 2'b01;
        /*outgoing_element_size*/
        memory[2] <= 0;
        memory[3] <= 8;
        /*num_outgoing_elements*/
        memory[4] <= 0;
        memory[5] <= 2;
        /*incoming_element_size*/
		memory[6] <= 0;
		memory[7] <= 9;
		/*num_write_extra_toggles*/
		memory[8] <= 0;
		memory[9] <= 3 + 4;
		/*num_read_extra_toggles*/
		memory[10] <= 0;
		memory[11] <= 0;
		/*write_buffer*/
        memory[12] <= 8'b00011010;
        memory[13] <= 8'b01101010;
		
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
endmodule
