/* Program: rv32um_mul
 * Purpose: local directed test for MUL/MULH/MULHSU/MULHU.
 * Pass rule: write 1 to tohost.
 * Fail rule: write 2 to tohost.
 */

    .section .text.start
    .globl _start

_start:
    li      t0, 7
    li      t1, 9
    mul     t2, t0, t1
    li      t3, 63
    bne     t2, t3, fail

    li      t4, -2
    li      t5, 3
    mulh    t6, t4, t5
    li      a1, -1
    bne     t6, a1, fail

    li      a2, -1
    li      a3, 2
    mulhsu  a4, a2, a3
    li      a5, -1
    bne     a4, a5, fail

    li      a6, -1
    li      a7, -1
    mulhu   s0, a6, a7
    li      s1, -2
    bne     s0, s1, fail

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
