`timescale 1ns / 1ps

module quick_spi #(
    parameter INCOMING_DATA_WIDTH = 8,
    parameter OUTGOING_DATA_WIDTH = 16,
    parameter EXTRA_WRITE_SCLK_TOGGLES = 6,
    parameter EXTRA_READ_SCLK_TOGGLES = 4,
    parameter NUMBER_OF_SLAVES = 2)
(
    input wire clk,
    input wire reset_n,
    input wire start_transaction,
    input wire[NUMBER_OF_SLAVES-1:0] slave,
    input wire operation,
    output reg end_of_transaction,
    output reg[INCOMING_DATA_WIDTH-1:0] incoming_data,
    input wire[OUTGOING_DATA_WIDTH-1:0] outgoing_data,
    output reg mosi,
    input wire miso,
    output reg sclk,
    output reg[NUMBER_OF_SLAVES-1:0] ss_n);

localparam READ = 1'b0;
localparam WRITE = 1'b1;

localparam READ_SCLK_TOGGLES = (INCOMING_DATA_WIDTH * 2) + 2;
localparam ALL_READ_TOGGLES = EXTRA_READ_SCLK_TOGGLES + READ_SCLK_TOGGLES;

integer sclk_toggle_count;
integer transaction_toggles;

reg spi_clock_phase;
reg[1:0] state;

localparam IDLE = 2'b00;
localparam SELECT_SLAVE = 2'b01;
localparam TRANSFER_DATA = 2'b10;

reg[INCOMING_DATA_WIDTH-1:0] incoming_data_buffer;

reg[7:0] memory [0: 255];

wire[7:0] CPOL = memory[0];
wire[7:0] CPHA = memory[1];

wire[7:0] incoming_element_size;
wire[7:0] outgoing_element_size = memory[2];
wire[7:0] num_outgoing_elements = memory[3];

reg[7:0] num_bits_read;
reg[7:0] num_bits_written;

reg[7:0] num_elements_written;

reg[3:0] incoming_byte_bit;
reg[3:0] outgoing_byte_bit;

reg[7:0] num_bytes_read;
reg[7:0] num_bytes_written;

reg[7:0] read_buffer_start;
reg[7:0] write_buffer_start;
    
always @ (posedge clk) begin
    if(!reset_n) begin
        memory[0] <= /*CPOL*/ 0;
        memory[1] <= /*CPHA*/ 0;
        memory[2] <= /*outgoing_element_size*/ 16;
        memory[3] <= /*num_outgoing_elements*/ 1; 
		
		num_elements_written <= 0;
        
		num_bits_read <= 0;
        num_bits_written <= 0;
		
		incoming_byte_bit <= 0;
		outgoing_byte_bit <= 0;
		
		num_bytes_read <= 0;
		num_bytes_written <= 0;
		
		read_buffer_start <= 30;
		write_buffer_start <= 4;
    
        end_of_transaction <= 1'b0;
        mosi <= 1'bz;
        sclk <= /*CPOL;*/0;
        ss_n <= {NUMBER_OF_SLAVES{1'b1}};
        sclk_toggle_count <= 0;
        transaction_toggles <= 0;
        spi_clock_phase <= /*CPHA;*/0;
        incoming_data <= 0;
        state <= IDLE;
    end
    
    else begin
        case(state)
            IDLE: begin
				if(start_transaction) begin
					transaction_toggles <= (operation == READ) ? ALL_READ_TOGGLES : EXTRA_WRITE_SCLK_TOGGLES;
					
                    memory[4] <= outgoing_data[15:8];
                    memory[5] <= outgoing_data[7:0];
					
					state <= SELECT_SLAVE;
				end
            end
            
            SELECT_SLAVE: begin
                ss_n[slave] <= 1'b0;
				
                if(!CPHA) begin
					outgoing_byte_bit <= outgoing_byte_bit + 1;
					mosi <= memory[write_buffer_start + num_bytes_written][outgoing_byte_bit];
					num_bits_written <= num_bits_written + 1;
                    
                    state <= TRANSFER_DATA;
                end
            end
            
            TRANSFER_DATA: begin
                sclk <= ~sclk;
				spi_clock_phase <= ~spi_clock_phase;
                sclk_toggle_count <= sclk_toggle_count + 1;
                
				case(spi_clock_phase)
					1'b0: begin
						if(num_bits_read != incoming_element_size) begin
							incoming_byte_bit <= incoming_byte_bit + 1;
						
							if(incoming_byte_bit == 7) begin
								num_bytes_read <= num_bytes_read + 1;
								incoming_byte_bit <= 0;
							end
							
							if(num_bits_read == incoming_element_size - 1) begin
								num_elements_read <= num_elements_read + 1;
							end
						
							memory[read_buffer_start + num_bytes_read][incoming_byte_bit] <= miso;
							num_bits_read <= num_bits_read + 1;
						end
					end
					
					1'b1: begin
						if(num_bits_written != outgoing_element_size) begin
							outgoing_byte_bit <= outgoing_byte_bit + 1;
							
							if(outgoing_byte_bit == 7) begin
								num_bytes_written <= num_bytes_written + 1;
								outgoing_byte_bit <= 0;
							end
							
							if(num_bits_written == outgoing_element_size - 1) begin
								num_elements_written <= num_elements_written + 1;
							end

							mosi <= memory[write_buffer_start + num_bytes_written][outgoing_byte_bit];
							num_bits_written <= num_bits_written + 1;
						end
					end					
				endcase
                
                if(sclk_toggle_count == (OUTGOING_DATA_WIDTH*2) + transaction_toggles) begin
                    ss_n[slave] <= 1'b1;
                    mosi <= 1'bz;
                    sclk <= CPOL;
                    spi_clock_phase <= CPHA;
                    sclk_toggle_count <= 0;
                    end_of_transaction <= 1'b1;
					
					num_bits_read = 0;
                    num_bits_written = 0;
					
					if(num_elements_written != num_outgoing_elements)
						state <= SELECT_SLAVE;
					else
						state <= IDLE;
                end
            end
        endcase
    end
end
endmodule
