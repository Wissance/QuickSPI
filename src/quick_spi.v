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
    input wire[NUMBER_OF_SLAVES-1:0] slave,
    input wire operation,
    output reg busy,
    output reg[INCOMING_DATA_WIDTH-1:0] incoming_data,
    input wire[OUTGOING_DATA_WIDTH-1:0] outgoing_data,
    output reg mosi,
    input wire miso,
    output reg sclk,
    output reg[NUMBER_OF_SLAVES-1:0] ss_n);

localparam READ = 1'b0;
localparam WRITE = 1'b1;

localparam READ_SCLK_TOGGLES = INCOMING_DATA_WIDTH * 2;
localparam ALL_READ_TOGGLES = EXTRA_READ_SCLK_TOGGLES + READ_SCLK_TOGGLES;

integer sclk_toggle_count;
integer transaction_toggles;

reg spi_clock_phase;
reg[1:0] state;

localparam IDLE = 1'b0;
localparam ACTIVE = 1'b1;

reg[INCOMING_DATA_WIDTH-1:0] incoming_data_buffer;
reg[OUTGOING_DATA_WIDTH-1:0] outgoing_data_buffer;
    
always @ (posedge clk) begin
    if(!reset_n) begin
        busy <= 1'b0;
        mosi <= 1'bz;
        ss_n <= {NUMBER_OF_SLAVES{1'b1}};
        sclk_toggle_count <= 0;
        transaction_toggles <= 0;
        spi_clock_phase <= ~CPHA;
        incoming_data <= {INCOMING_DATA_WIDTH{1'b0}};
        state <= IDLE;
    end
    
    else begin
        case(state)
            IDLE: begin                
                if(enable) begin
                    busy <= 1'b1;
                    sclk <= CPOL;
                    sclk_toggle_count <= 0;
                    transaction_toggles <= operation == READ ? ALL_READ_TOGGLES : EXTRA_WRITE_SCLK_TOGGLES;
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
                ss_n[slave] <= 1'b0;
                spi_clock_phase <= ~spi_clock_phase;
                
                if(ss_n[slave] == 1'b0) begin
                    if(sclk_toggle_count < (OUTGOING_DATA_WIDTH*2)+transaction_toggles) begin
                        sclk <= ~sclk;
                        sclk_toggle_count <= sclk_toggle_count + 1;
                    end
                end
                
                if(spi_clock_phase == 1'b0) begin
                    if(operation == READ) begin
                        if(sclk_toggle_count > ((OUTGOING_DATA_WIDTH*2)+EXTRA_READ_SCLK_TOGGLES)-1) begin
                            incoming_data_buffer <= incoming_data_buffer << 1;
                            incoming_data_buffer[0] <=  miso;
                        end
                    end
                end
                
                else begin 
                    if(sclk_toggle_count < (OUTGOING_DATA_WIDTH*2)-1) begin
                        mosi <= outgoing_data_buffer[OUTGOING_DATA_WIDTH - 1];
                        outgoing_data_buffer <= outgoing_data_buffer << 1;
                    end
                end
                
                if(sclk_toggle_count == (OUTGOING_DATA_WIDTH*2)+transaction_toggles) begin
                    busy <= 1'b0;
                    ss_n[slave] <= 1'b1; 
                    incoming_data <= incoming_data_buffer;
                    sclk_toggle_count <= 0;
                    state <= IDLE;
                end
            end
        endcase
    end
end
endmodule
