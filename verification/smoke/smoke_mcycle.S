/* Program: smoke_mcycle
 * Purpose: end-to-end smoke test for cycle/mcycle CSR reads on tb_cpu_top_isa.
 * Flow:
 *   1. Read cycle.
 *   2. Execute a few integer instructions.
 *   3. Read cycle again and ensure it increased.
 *   4. Read cycleh and mcycleh and ensure the aliases match.
 *   5. Store 1 to tohost on success, 2 on failure.
 */

    .section .text.start
    .globl _start

_start:
    .word   0xc0002373          /* rdcycle  t1 */
    addi    t0, zero, 11
    addi    t0, t0, 7
    addi    t0, t0, -3
    .word   0xc00023f3          /* rdcycle  t2 */
    bgeu    t1, t2, fail

    .word   0xc8002473          /* rdcycleh s0 */
    .word   0xb80024f3          /* rdmcycleh s1 */
    bne     s0, s1, fail

pass:
    la      a0, tohost
    li      a1, 1
    sw      a1, 0(a0)
1:
    j       1b

fail:
    la      a0, tohost
    li      a1, 2
    sw      a1, 0(a0)
2:
    j       2b
