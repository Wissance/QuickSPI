# QuickSPI

SPI Verilog module implementation with following features:

1. Settings
   a) Selecting byte order of data (Little/Big) and bits order (MSB/LSB)
   b) Adding extra toggles after transaction read or write operation (selecting number of toggles).
   c) AXI Interfaces for managing module from CPU (NOT IMPLEMRNTED YET, BUT WILL BD!)
2. Features:
   a) Divides input clock by 2.
