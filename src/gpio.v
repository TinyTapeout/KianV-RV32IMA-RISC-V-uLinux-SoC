/*
 *  gpio.v - a simple GPIO peripheral
 *
 *  copyright (c) 2025 Uri Shaked
 *
 *  permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  the software is provided "as is" and the author disclaims all warranties
 *  with regard to this software including all implied warranties of
 *  merchantability and fitness. in no event shall the author be liable for
 *  any special, direct, indirect, or consequential damages or any damages
 *  whatsoever resulting from loss of use, data or profits, whether in an
 *  action of contract, negligence or other tortious action, arising out of
 *  or in connection with the use or performance of this software.
 *
 */

`default_nettype none
module gpio (
    input wire clk,
    input wire resetn,

    input wire [7:0] ui_in,
    output reg [7:0] uo_out,
    output reg [7:0] uo_en,

    input wire ctrl,  /* 0: data, 1: uo_en */
    output reg [31:0] rdata,
    input wire [31:0] wdata,
    input wire [3:0] wstrb,
    input wire valid,
    output reg ready
);


  always @(posedge clk) begin
    if (!resetn) begin
      uo_out <= 8'b0;
      uo_en <= 8'b0;
      rdata <= 32'b0;
    end else begin
      ready <= 1'b0;
      if (valid) begin
        if (wstrb[0]) begin
          if (ctrl) begin
            uo_en <= wdata[7:0];
          end else begin
            uo_out <= wdata[7:0];
          end
        end

        ready <= 1'b1;
        rdata <= {24'b0, ctrl ? uo_en : ui_in};
      end
    end
  end

endmodule
