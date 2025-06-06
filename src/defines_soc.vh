/*
 *  kianv harris multicycle RISC-V rv32im
 *
 *  copyright (c) 2023 hirosh dabui <hirosh@dabui.de>
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
`ifndef KIANV_SOC
`define KIANV_SOC

`define BAUDRATE 2000000

`define REBOOT_ADDR 32'h 11_100_000
`define REBOOT_DATA 16'h 7777
`define HALT_DATA 16'h 5555

`define UART_TX_ADDR 32'h 10_000_000
`define UART_RX_ADDR 32'h 10_000_000
`define UART_LSR_ADDR 32'h 10_000_005
`define DIV_ADDR 32'h 10_000_010

`define KIANV_SPI_CTRL0 32'h 10_500_000
`define KIANV_SPI_DATA0 32'h 10_500_004
`define KIANV_SPI_DIV_ADDR 32'h 10_500_010

`define KIANV_GPIO_UO_EN 32'h 10_600_000
`define KIANV_GPIO_UO_OUT 32'h 10_600_004
`define KIANV_GPIO_UI_IN 32'h 10_600_008

//`define FAKE_MULTIPLIER

`define QUAD_SPI_FLASH_MODE 1'b1

`define SDRAM_MEM_ADDR_START 32'h 80_000_000
`define SDRAM_BANK_SIZE (1024*1024*8)
`define SDRAM_TOTAL_SIZE (1024*1024*16)
`define SDRAM_MEM_ADDR_END ((`SDRAM_MEM_ADDR_START) + (`SDRAM_TOTAL_SIZE))

`define SPI_NOR_MEM_ADDR_START 32'h 20_000_000

`define SPI_MEMORY_OFFSET (1024*1024)
`define SPI_NOR_MEM_ADDR_END ((`SPI_NOR_MEM_ADDR_START) + (16*1024*1024))

`define RESET_ADDR (`SPI_NOR_MEM_ADDR_START + `SPI_MEMORY_OFFSET)
//`define RESET_ADDR        0
`define FIRMWARE_BRAM ""
`define BRAM_WORDS (1024*2)

`endif
