/**
 * 32x32 register file with 2 read ports and 1 write port.
 */

module rf_top (
    // Power pins for the Gate Level test:
`ifdef GL_TEST
    inout wire VDPWR,
    inout wire VGND,
`endif

    input  wire [31:0] w_data,
    input  wire [ 4:0] w_addr,
    input  wire        w_ena,
    input  wire [ 4:0] ra_addr,
    input  wire [ 4:0] rb_addr,
    output reg  [31:0] ra_data,
    output reg  [31:0] rb_data,
    input  wire        clk
);

  reg [31:0] storage[0:31];

  initial begin
    integer i;
    for (i = 0; i < 32; i = i + 1) begin
      storage[i] = 32'h00000000;
    end
  end

  always @(posedge clk) begin
    if (w_ena) storage[w_addr] <= w_data;

    if (w_ena && (ra_addr == w_addr)) ra_data <= w_data;
    else ra_data <= storage[ra_addr];

    if (w_ena && (rb_addr == w_addr)) rb_data <= w_data;
    else rb_data <= storage[rb_addr];
  end


endmodule  /* rf_top */
