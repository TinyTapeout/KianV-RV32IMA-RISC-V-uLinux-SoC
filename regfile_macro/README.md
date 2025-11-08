## The register file

The register file macro being tested is an optimized SRAM macro organized as
32 words of 32 bits and offers three access ports : One write port and two
read ports.

It's been designed for TinyTapeout especially. It's compact enough ( ~ 88% of
the area of a single tile ) and doesn't use any DRC waiver/special rules.

The interface looks like this :

```verilog
module rf_top (
    input  wire [31:0] w_data,
    input  wire  [4:0] w_addr,
    input  wire        w_ena,
    input  wire  [4:0] ra_addr,
    input  wire  [4:0] rb_addr,
    output reg  [31:0] ra_data,
    output reg  [31:0] rb_data,
    input  wire        clk
);
```

For more information, see: https://github.com/smunaut/ttsky25b-rf-validation/blob/main/docs/info.md

