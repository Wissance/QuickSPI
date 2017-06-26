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
localparam ACTIVE = 2'b10;
localparam WAIT = 2'b11;

reg[INCOMING_DATA_WIDTH-1:0] incoming_data_buffer;
reg[OUTGOING_DATA_WIDTH-1:0] outgoing_data_buffer;

reg[7:0] memory [0: 255];

wire[7:0] num_outgoing_bits = memory[0];
wire[7:0] num_incoming_bits = memory[1];
wire[7:0] CPOL = memory[2];
wire[7:0] CPHA = memory[3];

reg[7:0] num_bits_written;
reg[7:0] num_bits_read;
    
always @ (posedge clk) begin
    if(!reset_n) begin
        memory[0] = /* num_outgoing_bits */ 16;
        memory[1] = /* num_incoming_bits */ 9;
        memory[2] = /*CPOL*/ 0;
        memory[3] = /*CPHA*/ 0;
        
        num_bits_written = 0;
        num_bits_read = 0;
    
        end_of_transaction <= 1'b0;
        mosi <= 1'bz;
        sclk <= CPOL;
        ss_n <= {NUMBER_OF_SLAVES{1'b1}};
        sclk_toggle_count <= 0;
        transaction_toggles <= 0;
        spi_clock_phase <= CPHA;
        incoming_data <= 0;
        incoming_data_buffer <= 0;
        outgoing_data_buffer <= 0;
        state <= IDLE;
    end
    
    else begin
        case(state)
            IDLE: begin
				if(start_transaction) begin
					transaction_toggles <= (operation == READ) ? ALL_READ_TOGGLES : EXTRA_WRITE_SCLK_TOGGLES;
					outgoing_data_buffer <= {outgoing_data[7:0], outgoing_data[15:8]};
					state <= SELECT_SLAVE;
				end
            end
            
            SELECT_SLAVE: begin
                ss_n[slave] <= 1'b0;
				
                if(!CPHA) begin
                    mosi <= outgoing_data_buffer[0];
                    outgoing_data_buffer <= outgoing_data_buffer >> 1;
                    num_bits_written <= num_bits_written + 1;
                    
                    state <= ACTIVE;
                end
            end
            
            ACTIVE: begin
                sclk <= ~sclk;
				spi_clock_phase <= ~spi_clock_phase;
                sclk_toggle_count <= sclk_toggle_count + 1;
                
				case(spi_clock_phase)
					1'b0: begin
						if(operation == READ) begin
							if(num_bits_read != num_incoming_bits) begin
								incoming_data_buffer <= incoming_data_buffer >> 1;
								incoming_data_buffer[INCOMING_DATA_WIDTH-1] <=  miso;
								
								num_bits_read <= num_bits_read + 1;
							end
						end
					end
					
					1'b1: begin
						if(num_bits_written != num_outgoing_bits) begin                        
							mosi <= outgoing_data_buffer[0];
							outgoing_data_buffer <= outgoing_data_buffer >> 1;
							
							num_bits_written <= num_bits_written + 1;
						end
					end					
				endcase
                
                if(sclk_toggle_count == (OUTGOING_DATA_WIDTH*2)+transaction_toggles) begin
                    ss_n[slave] <= 1'b1;
                    mosi <= 1'bz;
                    incoming_data <= incoming_data_buffer;
                    incoming_data_buffer <= 0;
                    outgoing_data_buffer <= 0;
                    sclk <= CPOL;
                    spi_clock_phase <= CPHA;
                    sclk_toggle_count <= 0;
                    end_of_transaction <= 1'b1;
                    
                    num_bits_written = 0;
                    num_bits_read = 0;
                    
                    state <= WAIT;
                end
            end
            
            WAIT: begin
                incoming_data <= 0;
                end_of_transaction <= 1'b0;
                state <= IDLE;
            end
        endcase
    end
end
endmodule
