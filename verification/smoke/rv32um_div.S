/* Program: rv32um_div
 * Purpose: local directed test for DIV/DIVU/REM/REMU.
 * Pass rule: write 1 to tohost.
 * Fail rule: write 2 to tohost.
 */

    .section .text.start
    .globl _start

_start:
    li      t0, 20
    li      t1, 6
    div     t2, t0, t1
    li      t3, 3
    bne     t2, t3, fail

    rem     t4, t0, t1
    li      t5, 2
    bne     t4, t5, fail

    li      t6, -1
    li      a1, 2
    divu    a2, t6, a1
    li      a3, 0x7fffffff
    bne     a2, a3, fail

    remu    a4, t6, a1
    li      a5, 1
    bne     a4, a5, fail

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
