# QuickSPI

SPI Verilog modules 2 SPI implementations:
1. Fully Hard for FPGA without CPU core like Spartan 6 or Cyclone 4, e.t.c.
   features:
   - setting bit (MSB, LSB) and bytes order (Little endian or Big endina)
   - adjustable number of extra clocks when some devices needs to make internal synchronizzation while CS is still active and clock keep going from clk (Dragster/Awaiba/Cmosis DR-2k-7)

2. Fully soft SPI with AXI Full interface with CPU. 

Docs on Russian: https://github.com/OpticalMeasurementsSystems/QuickSPI/wiki/How-to-use-:-%D0%9F%D0%BE%D0%BB%D0%BD%D0%BE%D0%B5-%D1%80%D1%83%D0%BA%D0%BE%D0%B2%D0%BE%D0%B4%D1%81%D1%82%D0%B2%D0%BE
