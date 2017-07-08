`timescale 1ns / 1ps

module quick_spi_tb;
reg clk;
reg rst_n;
wire end_of_transaction;
wire[7:0] incoming_data;
reg[15:0] outgoing_data;
wire mosi;
reg miso;
wire sclk;
wire[1:0] ss_n;
reg start_transaction;
reg operation;

integer sclk_toggle_count;
reg[8:0] incoming_data_buffer;
reg spi_clock_phase;

initial begin
    clk <= 1'b0;
    rst_n <= 1'b0;
    rst_n <= #50 1'b1;
end

always @ (posedge clk) begin
    if(!rst_n) begin
        outgoing_data <= {8'b00011010, 8'b01101010};
        operation <= 1'b0;
		miso <= 1'b0;
		sclk_toggle_count <= 0;
		incoming_data_buffer <= {8'b10010101, 1'b1};
		spi_clock_phase <= 1'b1;
    end
    
    else begin
        if(sclk_toggle_count > 36 && operation == 1'b0) begin
            if(!spi_clock_phase) begin
                miso <= incoming_data_buffer[0];
                incoming_data_buffer <= incoming_data_buffer >> 1;
            end
        end
        
        sclk_toggle_count <= sclk_toggle_count + 1;
        spi_clock_phase <= ~spi_clock_phase;
    end
end

quick_spi spi(
    .clk(clk),
    .reset_n(rst_n),
    .mosi(mosi),
    .miso(miso),
    .sclk(sclk),
    .ss_n(ss_n));

always #25 clk <= ~clk;

endmodule
