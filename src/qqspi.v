/*
 *  kianv harris RISCV project
 *
 *  copyright (c) 2022 hirosh dabui <hirosh@dabui.de>
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
/*
  re-implementation and extension of from https://github.com/machdyne/qqspi/blob/main/rtl/qqspi.v
  Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
*/
// added wmask, sync-comb fsm, spi flash support, cen polarity, faster during
// write operations: sb, sh behaves likes 8Mx32 memory
`default_nettype none
module qqspi #(
    parameter CHIP_SELECTS = 3
) (
    input wire [22:0] addr,  // 8Mx32
    output reg [31:0] rdata,
    input wire [31:0] wdata,
    input wire [3:0] wstrb,
    output reg ready,
    input wire valid,
    input wire clk,
    input wire resetn,
    input wire PSRAM_SPIFLASH,
    input wire QUAD_MODE,

    output reg  sclk,
    input  wire sio0_si_mosi_i,
    input  wire sio1_so_miso_i,
    input  wire sio2_i,
    input  wire sio3_i,

    output wire sio0_si_mosi_o,
    output wire sio1_so_miso_o,
    output wire sio2_o,
    output wire sio3_o,

    output reg [3:0] sio_oe,
    input wire [CHIP_SELECTS -1:0] ce_ctrl,
    output reg [CHIP_SELECTS -1:0] ce
);
  localparam [7:0] CMD_QUAD_WRITE = 8'h38;
  localparam [7:0] CMD_FAST_READ_QUAD = 8'hEB;
  localparam [7:0] CMD_WRITE = 8'h02;
  localparam [7:0] CMD_READ = 8'h03;

  //reg  [3:0] sio_oe;
  reg [3:0] sio_out;
  wire [3:0] sio_in;

  wire write;
  assign write = |wstrb;
  wire read;
  assign read = ~write;

  assign {sio3_o, sio2_o, sio1_so_miso_o, sio0_si_mosi_o} = sio_out;
  assign sio_in = {sio3_i, sio2_i, sio1_so_miso_i, sio0_si_mosi_i};

  localparam [2:0] S0_IDLE = 3'd0;
  localparam [2:0] S1_SELECT_DEVICE = 3'd1;
  localparam [2:0] S2_CMD = 3'd2;
  localparam [2:0] S4_ADDR = 3'd3;
  localparam [2:0] S5_WAIT = 3'd4;
  localparam [2:0] S6_XFER = 3'd5;
  localparam [2:0] S7_WAIT_FOR_XFER_DONE = 3'd6;

  reg [2:0] state, next_state;
  reg [31:0] spi_buf;
  reg [5:0] xfer_cycles;
  reg is_quad;

  reg [31:0] rdata_next;

  reg sclk_next;
  reg [3:0] sio_oe_next;
  reg [3:0] sio_out_next;
  reg [31:0] spi_buf_next;
  reg is_quad_next;
  reg [5:0] xfer_cycles_next;
  reg ready_next;
  reg [CHIP_SELECTS -1:0] ce_next;

  wire [1:0] byte_offset;
  wire [5:0] wr_cycles;
  wire [31:0] wr_buffer;

  align_wdata align_wdata_i (
      .wstrb      (wstrb),
      .wdata      (wdata),
      .byte_offset(byte_offset),
      .wr_cycles  (wr_cycles),
      .wr_buffer  (wr_buffer)
  );

  always @(posedge clk) begin
    if (!resetn) begin
      ce <= ~0;
      sclk <= 1'b1;
      sio_oe <= 4'b0000;
      sio_out <= 4'b0000;
      spi_buf <= 0;
      is_quad <= 0;
      xfer_cycles <= 0;
      ready <= 0;
      state <= S0_IDLE;
    end else begin
      state <= next_state;
      ce <= ce_next;
      sclk <= sclk_next;
      sio_oe <= sio_oe_next;
      sio_out <= sio_out_next;
      spi_buf <= spi_buf_next;
      is_quad <= is_quad_next;
      xfer_cycles <= xfer_cycles_next;
      rdata <= rdata_next;
      ready <= ready_next;
    end
  end

  always @(*) begin
    next_state = state;
    ce_next = ce;
    sclk_next = sclk;
    sio_oe_next = sio_oe;
    sio_out_next = sio_out;
    spi_buf_next = spi_buf;
    is_quad_next = is_quad;
    xfer_cycles_next = xfer_cycles;
    ready_next = ready;
    rdata_next = rdata;
    xfer_cycles_next = xfer_cycles;

    if (|xfer_cycles) begin

      sio_out_next[3:0] = is_quad ? spi_buf[31:28] : {3'b0, spi_buf[31]};

      if (sclk) begin
        sclk_next = 1'b0;
      end else begin
        sclk_next = 1'b1;
        spi_buf_next = is_quad ? {spi_buf[27:0], sio_in[3:0]} : {spi_buf[30:0], sio_in[1]};
        xfer_cycles_next = is_quad ? xfer_cycles - 4 : xfer_cycles - 1;
      end

    end else begin
      case (state)
        S0_IDLE: begin
          sio_oe_next  = 4'b0001;
          is_quad_next = 0;
          if (valid && !ready) begin
            next_state = S1_SELECT_DEVICE;
            xfer_cycles_next = 0;
          end else if (!valid && ready) begin
            ready_next = 1'b0;
            ce_next = ~0;
          end else begin
            ce_next = ~0;
          end
        end

        S1_SELECT_DEVICE: begin
          ce_next = ~ce_ctrl;
          next_state = S2_CMD;
        end

        S2_CMD: begin
          if (QUAD_MODE) begin
            spi_buf_next[31:24] = write ? CMD_QUAD_WRITE : CMD_FAST_READ_QUAD;
          end else begin
            spi_buf_next[31:24] = write ? CMD_WRITE : CMD_READ;
          end

          xfer_cycles_next = 8;
          next_state = S4_ADDR;
        end

        S4_ADDR: begin
          if (PSRAM_SPIFLASH) begin
            spi_buf_next[31:8] = {1'b0, {addr[20:0], write ? byte_offset : 2'b00}};
          end else begin
            spi_buf_next[31:8] = {{addr[21:0], write ? byte_offset : 2'b00}};
          end

          sio_oe_next = QUAD_MODE ? 4'b1111 : 4'b0001;
          xfer_cycles_next = 24;

          is_quad_next = QUAD_MODE;
          next_state = QUAD_MODE && read ? S5_WAIT : S6_XFER;
        end

        S5_WAIT: begin
          sio_oe_next = 4'b0000;
          xfer_cycles_next = 6;
          is_quad_next = 0;
          next_state = S6_XFER;
        end

        S6_XFER: begin
          is_quad_next = QUAD_MODE;

          if (write) begin
            sio_oe_next  = QUAD_MODE ? 4'b1111 : 4'b0001;
            spi_buf_next = wr_buffer;
          end else begin
            sio_oe_next = QUAD_MODE ? 4'b0000 : 4'b0001;
          end

          xfer_cycles_next = write ? wr_cycles : 32;
          next_state = S7_WAIT_FOR_XFER_DONE;
        end

        S7_WAIT_FOR_XFER_DONE: begin
          if (PSRAM_SPIFLASH) begin
            rdata_next = spi_buf;
          end else begin
            // transform from little to big endian
            rdata_next = {spi_buf[7:0], spi_buf[15:8], spi_buf[23:16], spi_buf[31:24]};
          end
          ready_next = 1'b1;
          next_state = S0_IDLE;
        end

        default: next_state = S0_IDLE;
      endcase

    end

  end

endmodule

module align_wdata (
    input  wire [ 3:0] wstrb,
    input  wire [31:0] wdata,
    output reg  [ 1:0] byte_offset,
    output reg  [ 5:0] wr_cycles,
    output reg  [31:0] wr_buffer
);
  always @(*) begin
    wr_buffer = wdata;
    case (wstrb)
      4'b0001: begin
        byte_offset = 3;
        wr_buffer[31:24] = wdata[7:0];
        wr_cycles = 8;
      end
      4'b0010: begin
        byte_offset = 2;
        wr_buffer[31:24] = wdata[15:8];
        wr_cycles = 8;
      end
      4'b0100: begin
        byte_offset = 1;
        wr_buffer[31:24] = wdata[23:16];
        wr_cycles = 8;
      end
      4'b1000: begin
        byte_offset = 0;
        wr_buffer[31:24] = wdata[31:24];
        wr_cycles = 8;
      end
      4'b0011: begin
        byte_offset = 2;
        wr_buffer[31:16] = wdata[15:0];
        wr_cycles = 16;
      end
      4'b1100: begin
        byte_offset = 0;
        wr_buffer[31:16] = wdata[31:16];
        wr_cycles = 16;
      end
      4'b1111: begin
        byte_offset = 0;
        wr_buffer[31:0] = wdata[31:0];
        wr_cycles = 32;
      end
      default: begin
        byte_offset = 0;
        wr_buffer   = wdata;
        wr_cycles   = 32;
      end
    endcase
  end
endmodule
