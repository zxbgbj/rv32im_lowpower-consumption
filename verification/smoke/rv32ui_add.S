/* Program: rv32ui_add
 * Purpose: local directed test for ADD/SUB style integer datapath checks.
 * Pass rule: write 1 to tohost.
 * Fail rule: write 2 to tohost.
 */

    .section .text.start
    .globl _start

_start:
    li      t0, 11
    li      t1, 13
    add     t2, t0, t1
    li      t3, 24
    bne     t2, t3, fail

    sub     t4, t2, t0
    li      t5, 13
    bne     t4, t5, fail

    xor     t6, t0, t1
    li      a1, 6
    bne     t6, a1, fail

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
