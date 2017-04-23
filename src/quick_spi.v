`timescale 1ns / 1ps

module quick_spi #(
    parameter INCOMING_DATA_WIDTH = 8,
    parameter OUTGOING_DATA_WIDTH = 16,
    parameter CPOL = 0,
    parameter CPHA = 0,
    parameter EXTRA_WRITE_SCLK_TOGGLES = 6,
    parameter EXTRA_READ_SCLK_TOGGLES = 4,
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

integer sclk_toggle_count;
reg spi_clock_phase;
    
reg[1:0] state;
reg[NUMBER_OF_SLAVES-1:0] slave;

reg[INCOMING_DATA_WIDTH-1:0] incoming_data_buffer;
reg[OUTGOING_DATA_WIDTH-1:0] outgoing_data_buffer;

localparam IDLE = 1'b0;
localparam ACTIVE = 1'b1;
    
always @ (posedge clk) begin
    if(!reset_n) begin
        busy <= 1'b0;
        mosi <= 1'bz;
        ss_n <= {NUMBER_OF_SLAVES{1'b1}};
        sclk_toggle_count <= 0;
        spi_clock_phase = ~CPHA;
        incoming_data <= {INCOMING_DATA_WIDTH{1'b0}};
        state <= IDLE;
        
        slave = 2'b01;
    end
    
    else begin
        case(state)
            IDLE: begin                
                if(enable) begin
                    busy <= 1'b1;
                    sclk <= CPOL;
                    sclk_toggle_count <= 0;
                    spi_clock_phase = ~CPHA;
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
                
                /*MARK*/
                if(sclk_toggle_count < (OUTGOING_DATA_WIDTH*2)+EXTRA_WRITE_SCLK_TOGGLES && ss_n[slave] == 1'b0)
                    sclk <= ~sclk;
                    
                /*if(sclk_toggle_count < OUTGOING_DATA_WIDTH && spi_clock_phase == 1'b0) begin
                    incoming_data_buffer[0] <=  miso;
                    incoming_data_buffer <= incoming_data_buffer << 1;
                end*/
                    
                if(sclk_toggle_count < (OUTGOING_DATA_WIDTH*2)-1 && spi_clock_phase == 1'b1) begin
                    mosi <= outgoing_data_buffer[OUTGOING_DATA_WIDTH - 1];
                    outgoing_data_buffer <= outgoing_data_buffer << 1;
                end
                
                /*MARK*/
                if(sclk_toggle_count < (OUTGOING_DATA_WIDTH*2)+EXTRA_WRITE_SCLK_TOGGLES && ss_n[slave] == 1'b0)
                    sclk_toggle_count <= sclk_toggle_count + 1;
                else
                    sclk_toggle_count <= 0;
                
                /*MARK*/    
                /* END OF TRANSACTION*/    
                if(sclk_toggle_count == (OUTGOING_DATA_WIDTH*2)+EXTRA_WRITE_SCLK_TOGGLES) begin
                    ss_n[slave] <= 1'b1; 
                    state <= IDLE;
                end
            end
        endcase
    end
end
endmodule
