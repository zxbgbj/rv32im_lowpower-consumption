/* Program: rv32ui_branch
 * Purpose: local directed test for BEQ/BNE/BLT/BGE/BLTU/BGEU.
 * Pass rule: write 1 to tohost.
 * Fail rule: write 2 to tohost.
 */

    .section .text.start
    .globl _start

_start:
    li      t0, 5
    li      t1, 5
    beq     t0, t1, 1f
    j       fail
1:
    bne     t0, t1, fail

    li      t2, -3
    li      t3, 5
    blt     t2, t3, 2f
    j       fail
2:
    bge     t3, t2, 3f
    j       fail
3:
    li      t4, -1
    li      t5, 1
    bltu    t5, t4, 4f
    j       fail
4:
    bgeu    t4, t5, pass
    j       fail

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
