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

integer sclk_toggle_count2;
reg[8:0] incoming_data_buffer2;
reg spi_clock_phase2;

initial begin
    clk <= 1'b0;
    rst_n <= 1'b0;
    rst_n <= #50 1'b1;
    
    miso <= 1'b0;
    sclk_toggle_count2 <= 0;
    incoming_data_buffer2 <= 9'b110010101;
    spi_clock_phase2 <= 1'b1;
end

always @ (posedge clk) begin
    if(!rst_n) begin
        outgoing_data <= 16'b0101101001011010;
        enable <= 1'b1;
        start_transaction <= 1'b1;
        operation <= 1'b0;
    end
    
    else begin
        if(end_of_transaction) begin
            operation <= ~operation;
            sclk_toggle_count2 <= 0;
        end
        
       /* if(sclk_toggle_count2 > 36) begin
            if(!spi_clock_phase2) begin
                miso <= incoming_data_buffer2[8];
                incoming_data_buffer2 <= incoming_data_buffer2 << 1;
            end
        end
        
        sclk_toggle_count2 <= sclk_toggle_count2 + 1;
        spi_clock_phase2 <= ~spi_clock_phase2;*/
    end
end


always @ (negedge sclk) begin
    if(sclk_toggle_count2 > 17) begin
        miso <= incoming_data_buffer2[8];
        incoming_data_buffer2 <= incoming_data_buffer2 << 1;
    end
    
    //spi_clock_phase <= ~spi_clock_phase;
    sclk_toggle_count2 <= sclk_toggle_count2 + 1;
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
