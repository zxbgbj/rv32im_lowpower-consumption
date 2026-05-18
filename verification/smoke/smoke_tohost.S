/* Program: smoke_tohost
 * Purpose: tiny bare-metal ISA smoke program for tb_cpu_top_isa.
 * Flow:
 *   1. Execute a few RV32I/RV32M operations.
 *   2. Store 1 to tohost on success.
 *   3. Store 2 to tohost on failure.
 * Memory contract:
 *   - tohost is provided by the linker at address 0x00000100.
 */

    .section .text.start
    .globl _start

_start:
    li      t0, 5
    li      t1, 7
    add     t2, t0, t1
    li      t3, 12
    bne     t2, t3, fail

    li      t4, 3
    mul     t5, t4, t3
    li      t6, 36
    bne     t5, t6, fail

    la      a0, tohost
    sw      zero, 0(a0)
    lw      a1, 0(a0)
    bne     a1, zero, fail

pass:
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
