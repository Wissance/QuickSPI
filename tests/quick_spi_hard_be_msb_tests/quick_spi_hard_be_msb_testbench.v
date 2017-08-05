`timescale 1ns / 1ps

module quick_spi_hard_be_msb_testbench;
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

integer sclk_toggle_count;
reg[8:0] incoming_data_buffer;
reg spi_clock_phase;

initial begin
    clk <= 1'b0;
    rst_n <= 1'b0;
    rst_n <= #50 1'b1;
    outgoing_data <= {8'b11001100, 8'b10000010};
end

always @ (posedge clk) 
begin
    if(!rst_n) 
    begin
        outgoing_data <= {8'b11001100, 8'b10000010};
        enable <= 1'b1;
        start_transaction <= 1'b1;
        operation <= 1'b0;
		miso <= 1'b0;
		sclk_toggle_count <= 0;
		incoming_data_buffer <= {8'b10010101, 1'b1};
		spi_clock_phase <= 1'b1;
    end
    
    else 
    begin
        if(end_of_transaction) 
        begin
            operation <= ~operation;
            sclk_toggle_count <= 0;
            spi_clock_phase <= 1'b1;
            incoming_data_buffer <= {8'b10010101, 1'b1};
			miso <= 1'b0;
        end
        
        else 
        begin
            if(sclk_toggle_count > 36) 
            begin
                if(!spi_clock_phase) 
                begin
                    miso <= incoming_data_buffer[0];
                    incoming_data_buffer <= incoming_data_buffer >> 1;
                end
            end
            
            sclk_toggle_count <= sclk_toggle_count + 1;
            spi_clock_phase <= ~spi_clock_phase;
        end
    end
end

quick_spi_hard #
(
    .BYTES_ORDER(1), // big endian,
    .BITS_ORDER(1)   // MSB First
)
spi
(
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
    .ss_n(ss_n)
);

always #25 clk <= ~clk;

endmodule
