`timescale 1ns / 1ps

module quick_spi #(
    parameter INCOMING_DATA_WIDTH = 8,
    parameter OUTGOING_DATA_WIDTH = 16,
    parameter NUMBER_OF_SLAVES = 2)
(
    input wire clk,
    input wire reset_n,
    input wire enable,
    output reg busy,
    output reg[INCOMING_DATA_WIDTH-1:0] incoming_data,
    input wire[OUTGOING_DATA_WIDTH-1:0] outgoing_data,
    output reg mosi,
    input wire miso,
    output reg sclk,
    output reg[NUMBER_OF_SLAVES-1:0] ss_n);

integer spi_clock_count;
reg spi_clock_phase;
    
reg[1:0] state;
reg[NUMBER_OF_SLAVES-1:0] slave;

reg[INCOMING_DATA_WIDTH-1:0] incoming_data_buffer;
reg[OUTGOING_DATA_WIDTH-1:0] outgoing_data_buffer;

localparam CPOL = 0;
localparam CPHA = 0;

localparam IDLE = 1'b0;
localparam ACTIVE = 1'b1;
    
always @ (posedge clk) begin
    if(!reset_n) begin
        busy <= 1'b0;
        mosi <= 1'bz;
        ss_n <= {NUMBER_OF_SLAVES{1'b1}};
        spi_clock_count <= 0;
        spi_clock_phase = ~CPHA;
        incoming_data <= {INCOMING_DATA_WIDTH{1'b0}};
        slave = 2'b01;
        state <= IDLE;
    end
    
    else begin
        case(state)
            IDLE: begin                
                if(enable) begin
                    busy <= 1'b1;
                    sclk <= CPOL;
                    spi_clock_count <= 0;
                    outgoing_data_buffer <= outgoing_data;
                    state <= ACTIVE;
                end
                
                else begin
                    busy <= 1'b0;
                    ss_n <= {NUMBER_OF_SLAVES{1'b1}};
                    mosi <= 1'bz;
                end
            end
            
            ACTIVE: begin
                busy <= 1'b1;
                ss_n[slave] <= 1'b0;
                spi_clock_phase <= ~spi_clock_phase;
                
                if(spi_clock_count < OUTGOING_DATA_WIDTH - 1 && ss_n[slave] == 1'b0)
                    sclk <= ~sclk;
                    
                if(spi_clock_count < OUTGOING_DATA_WIDTH && spi_clock_phase == 1'b0) begin
                    incoming_data_buffer[0] <=  miso;
                    incoming_data_buffer <= incoming_data_buffer << 1;
                end
                    
                if(spi_clock_count < OUTGOING_DATA_WIDTH && spi_clock_phase == 1'b1) begin
                    mosi <= outgoing_data_buffer[OUTGOING_DATA_WIDTH - 1];
                    outgoing_data_buffer <= outgoing_data_buffer << 1;
                end
                
                if(spi_clock_count == OUTGOING_DATA_WIDTH - 1 /* 15 */)
                    spi_clock_count <= 0;
                else
                    spi_clock_count <= spi_clock_count + 1;
            end
        endcase
    end
end
endmodule
