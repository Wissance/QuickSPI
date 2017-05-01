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
reg enable;
reg start_transaction;
reg operation;

initial begin
    clk <= 1'b0;
    rst_n <= 1'b0;
    rst_n <= #50 1'b1;
end

always @ (posedge clk) begin
    if(!rst_n) begin
        miso <= 1'b1;
        outgoing_data <= 16'b0101101001011010;
        enable <= 1'b1;
        start_transaction <= 1'b1;
        operation <= 1'b1;
    end
    
    else begin
        if(end_of_transaction) begin
            operation <= ~operation;
        end
    end
end

quick_spi spi(
    .clk(clk),
    .reset_n(rst_n),
    .enable(enable),
    .start_transaction(start_transaction),
    .slave(2'b01),
    .operation(operation),
    .end_of_transaction(end_of_transaction),
    .incoming_data(incoming_data),
    .outgoing_data(outgoing_data),
    .mosi(mosi),
    .miso(miso),
    .sclk(sclk),
    .ss_n(ss_n));

always #25 clk <= ~clk;

endmodule
