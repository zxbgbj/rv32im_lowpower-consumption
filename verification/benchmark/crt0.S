.section .text.init
.globl _start

_start:
    la sp, __stack_top

    la t0, __bss_start
    la t1, __bss_end
.Lzero_bss:
    bgeu t0, t1, .Lbss_done
    sw zero, 0(t0)
    addi t0, t0, 4
    j .Lzero_bss

.Lbss_done:
    call benchmark_init
    call main
    call benchmark_exit

.Lhang:
    j .Lhang
