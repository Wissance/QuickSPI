`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2017 09:36:17
// Design Name: 
// Module Name: quick_spi_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


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

initial begin
    miso <= 1'b1;
    outgoing_data <= 16'b0101101001011010;

    clk <= 1'b0;
    rst_n <= 1'b0;
    rst_n <= #50 1'b1; 
end

quick_spi spi(
    .clk(clk),
    .reset_n(rst_n),
    .enable(1'b1),
    .busy(busy),
    .incoming_data(incoming_data),
    .outgoing_data(outgoing_data),
    .mosi(mosi),
    .miso(miso),
    .sclk(sclk),
    .ss_n(ss_n));

always #25 clk <= ~clk;

endmodule
