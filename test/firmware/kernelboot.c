// SPDX-FileCopyrightText: © 2023 Uri Shaked <uri@wokwi.com>
// SPDX-FileCopyrightText: © 2023 Hirosh Dabui <hirosh@dabui.de>
// SPDX-License-Identifier: MIT

#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>

#define IO_BASE 0x10000000
#define UART_TX (IO_BASE)
#define UART_RX (IO_BASE)
#define UART_LSR (IO_BASE + 0x5)
#define SPI_DIV (IO_BASE + 0x500010)
#define LSR_THRE 0x20
#define LSR_TEMT 0x40
#define LSR_DR 0x01
#define GPIO_BASE 0x10600000
#define GPIO_UO_EN (GPIO_BASE + 0x0000)
#define GPIO_UO_OUT (GPIO_BASE + 0x0004)
#define GPIO_UI_IN (GPIO_BASE + 0x0008)
#define MTIME (*((volatile uint64_t *)0x11004000))
#define RAM_HIGH 0x80800000

volatile char *uart_tx = (char *)UART_TX, *uart_rx = (char *)UART_RX,
              *uart_lsr = (char *)UART_LSR;
volatile char *gpio_uo_en = (char *)GPIO_UO_EN,
              *gpio_uo_out = (char *)GPIO_UO_OUT,
              *gpio_ui_in = (char *)GPIO_UI_IN;
volatile uint32_t *ram_high = (uint32_t *)RAM_HIGH;
volatile atomic_uint interrupt_occurred = ATOMIC_VAR_INIT(0);

void uart_putc(char c) {
  while (!(*uart_lsr & (LSR_THRE | LSR_TEMT)))
    ;
  *uart_tx = c;
}

char uart_getc() {
  while (!(*uart_lsr & LSR_DR))
    ;
  return *uart_rx;
}

void uart_puthex_byte(uint8_t byte) {
  const char hex_chars[] = "0123456789ABCDEF";
  uart_putc(hex_chars[byte >> 4]);
  uart_putc(hex_chars[byte & 0xF]);
}

void uart_puthex(const void *data, size_t size) {
  const uint8_t *bytes = (const uint8_t *)data;
  for (size_t i = 0; i < size; i++) {
    uart_puthex_byte(bytes[i]);
    uart_putc(' ');
  }
}

static inline void enable_interrupts() { asm volatile("csrsi mstatus, 8"); }
static inline void disable_interrupts() { asm volatile("csrci mstatus, 8"); }

void setup_timer_interrupt() {
  uint32_t mie;
  asm volatile("csrr %0, mie" : "=r"(mie));
  mie |= (1 << 7);
  asm volatile("csrw mie, %0" ::"r"(mie));
}

__attribute__((naked)) void timer_interrupt_handler(void) {
  asm volatile(
    "addi sp, sp, -24\n"
    "sw x1, 4(sp)\n"
    "sw x2, 8(sp)\n"
    "sw t0, 12(sp)\n"
    "sw a4, 16(sp)\n"
    "sw a5, 20(sp)\n"
  );
  asm volatile("csrrc t0, mstatus, %0" : : "r"((uint32_t)(1 << 7)) : "t0");
  asm volatile("csrc mstatus, %0" ::"r"((uint32_t)(1 << 3)) : "t0");
  atomic_store(&interrupt_occurred, 1);
  asm volatile(
    "lw x1, 4(sp)\n"
    "lw x2, 8(sp)\n"
    "lw t0, 12(sp)\n"
    "lw a4, 16(sp)\n"
    "lw a5, 20(sp)\n"
    "addi sp, sp, 24\n"
    "mret\n"
  );
}

struct spi_regs {
  volatile uint32_t *ctrl, *data;
} spi = {(volatile uint32_t *)0x10500000, (volatile uint32_t *)0x10500004};

static void spi_set_cs(int cs_n) { *spi.ctrl = cs_n; }
static int spi_xfer(char *tx, char *rx) {
  while ((*spi.ctrl & 0x80000000) != 0)
    ;
  *spi.data = (tx != NULL) ? *tx : 0;
  while ((*spi.ctrl & 0x80000000) != 0)
    ;
  if (rx)
    *rx = (char)(*spi.data);
  return 0;
}

uint8_t SPI_transfer(char tx) {
  uint8_t rx;
  spi_xfer(&tx, &rx);
  return rx;
}

uint8_t test_ram_high() {
  *ram_high = 0x12345678;
  if (*ram_high != 0x12345678) {
    return 0;
  }

  *ram_high = 0x87654321;
  if (*ram_high != 0x87654321) {
    return 0;
  }

  return 1;
}

#define CS_ENABLE() spi_set_cs(1)
#define CS_DISABLE() spi_set_cs(0)

int main() {
  setup_timer_interrupt();
  uint64_t interval = 2, *mtime = (volatile uint64_t *)0x1100bff8,
           *mtimecmp = (volatile uint64_t *)0x11004000;
  *mtimecmp = *mtime + interval;
  uint32_t *spi_div = (volatile uint32_t *)SPI_DIV;
  enable_interrupts();

  // Test High RAM
  if (!test_ram_high()) {
    uart_putc('E');
    uart_putc('!');
    return 1;
  }

  // Test GPIO (only if test_sel is set)
  if (*gpio_ui_in & 1) {
     *gpio_uo_en = 0xff;
     *gpio_uo_out = 0x80; // Start of test marker
     *gpio_uo_out = 0x00;
     *gpio_uo_out = 0x85;
     *gpio_uo_out = 0x12;
     *gpio_uo_out = 0x94;
     *gpio_uo_out = 0x17;
     *gpio_uo_out = 0x80; // End of test marker
     *gpio_uo_en = 0;
  }

  // Test SPI
  uint8_t rx = 0;
  CS_ENABLE();
  if ((rx = SPI_transfer(0xde)) != 0xde >> 1)
    return 1;
  if ((rx = SPI_transfer(0xad)) != 0xad >> 1)
    return 1;
  if ((rx = SPI_transfer(0xbe)) != 0xdf >> 0)
    return 1;
  if ((rx = SPI_transfer(0xaf)) != 0xaf >> 1)
    return 1;
  CS_DISABLE();

  while (!atomic_load(&interrupt_occurred))
    ;

  // Test UART
  for (char *str = "Hello UART\n"; *str; uart_putc(*str++))
    ;

  while (1) {
    char c = uart_getc();
    uart_putc(c >= 'A' && c <= 'Z' ? c + 32 : c);
  }

  return 0;
}
