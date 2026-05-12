// Fibonacci Demo
// Computes Fibonacci numbers iteratively, outputs each over UART,
// and displays the current value on the LEDs.

#include "mmio.h"

int main(void) {
    uart_puts("=== Fibonacci on RISC-V ===\r\n");

    int a = 0, b = 1;
    int n = 20;     // compute first 20 Fibonacci numbers

    for (int i = 0; i < n; i++) {
        uart_puts("F(");
        uart_put_dec(i);
        uart_puts(") = ");
        uart_put_dec(a);
        uart_puts("\r\n");

        // Display lower 16 bits on LEDs
        LED_REG = a & 0xFFFF;

        int next = a + b;
        a = b;
        b = next;
    }

    uart_puts("Done.\r\n");

    return 0;
}
