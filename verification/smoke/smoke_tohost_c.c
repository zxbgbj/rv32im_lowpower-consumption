/* Program: smoke_tohost_c
 * Purpose: tiny bare-metal C smoke program for tb_cpu_top_isa.
 * Entry: _start is used directly as the linker entry symbol.
 * Pass rule: write 1 to tohost.
 * Fail rule: write 2 to tohost.
 */

extern volatile unsigned int tohost;

void _start(void) {
    unsigned int a = 5u;
    unsigned int b = 7u;
    unsigned int sum = a + b;
    unsigned int prod = 3u * sum;

    if (sum != 12u) {
        tohost = 2u;
        for (;;) { }
    }

    if (prod != 36u) {
        tohost = 2u;
        for (;;) { }
    }

    tohost = 0u;
    if (tohost != 0u) {
        tohost = 2u;
        for (;;) { }
    }

    tohost = 1u;
    for (;;) { }
}
