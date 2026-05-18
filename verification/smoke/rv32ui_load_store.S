/* Program: rv32ui_load_store
 * Purpose: local directed test for SW/LW/SB/LB/LBU/LH/LHU paths.
 * Pass rule: write 1 to tohost.
 * Fail rule: write 2 to tohost.
 */

    .section .text.start
    .globl _start

_start:
    la      t0, scratch
    li      t1, 0x11223344
    sw      t1, 0(t0)
    lw      t2, 0(t0)
    bne     t1, t2, fail

    li      t3, -8
    sb      t3, 4(t0)
    lb      t4, 4(t0)
    li      t5, -8
    bne     t4, t5, fail
    lbu     t6, 4(t0)
    li      a1, 248
    bne     t6, a1, fail

    li      a2, 0x00008001
    sh      a2, 8(t0)
    lh      a3, 8(t0)
    li      a4, -32767
    bne     a3, a4, fail
    lhu     a5, 8(t0)
    li      a6, 0x00008001
    bne     a5, a6, fail

pass:
    la      a0, tohost
    li      a2, 1
    sw      a2, 0(a0)
1:
    j       1b

fail:
    la      a0, tohost
    li      a2, 2
    sw      a2, 0(a0)
2:
    j       2b

    .section .bss
    .align 4
scratch:
    .space 16
