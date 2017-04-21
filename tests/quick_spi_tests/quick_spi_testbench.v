`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.04.2017 12:58:16
// Design Name: 
// Module Name: quick_spi_testbench
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


module quick_spi_testbench;
    reg clk;
    reg rst;
    
    wire miso;
    wire mosi;
    wire sck;
    reg start;
    
    reg[7:0] data_in;
    wire[7:0] data_out;
    
    wire busy;
    wire new_data;
    
    initial begin
        clk <= 1'b0;
        rst <= 1'b0;
        start <= 1'b0;
        data_in <= #50 8'b01101100;
        rst <= #50 1'b1;
        start <= #50 1'b1;
    end
    
    always #25 clk <= ~clk;

    quick_spi #(.CLK_DIV(2))
        spi(
            .clk(clk),
            .rst(rst),
            .miso(miso),
            .mosi(mosi),
            .sck(sck),
            .start(start),
            .data_in(data_in),
            .data_out(data_out),
            .busy(busy),
            .new_data(new_data));
endmodule
