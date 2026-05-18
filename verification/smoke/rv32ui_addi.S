/* Program: rv32ui_addi
 * Purpose: local directed test for immediate integer operations.
 * Pass rule: write 1 to tohost.
 * Fail rule: write 2 to tohost.
 */

    .section .text.start
    .globl _start

_start:
    li      t0, 8
    addi    t1, t0, 9
    li      t2, 17
    bne     t1, t2, fail

    andi    t3, t1, 3
    li      t4, 1
    bne     t3, t4, fail

    ori     t5, t3, 8
    li      t6, 9
    bne     t5, t6, fail

    xori    a1, t6, 12
    li      a2, 5
    bne     a1, a2, fail

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
