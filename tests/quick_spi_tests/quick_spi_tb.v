`timescale 1ns / 1ps

module quick_spi_tb;
reg clk;
reg rst_n;
wire busy;
wire[7:0] incoming_data;
reg[15:0] outgoing_data;

wire mosi;
reg miso;
wire sclk;
wire[1:0] ss_n;
reg enable;

initial begin
    miso <= 1'b1;
    outgoing_data <= 16'b0101101001011010;

    clk <= 1'b0;
    rst_n <= 1'b0;
    enable <= 1'b1;
    
    rst_n <= #50 1'b1;
    enable <= #100 1'b0; 
end

quick_spi spi(
    .clk(clk),
    .reset_n(rst_n),
    .enable(enable),
    .slave(2'b01),
    .operation(1'b1),
    .busy(busy),
    .incoming_data(incoming_data),
    .outgoing_data(outgoing_data),
    .mosi(mosi),
    .miso(miso),
    .sclk(sclk),
    .ss_n(ss_n));

always #25 clk <= ~clk;

endmodule
