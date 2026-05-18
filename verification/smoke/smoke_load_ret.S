/* Program: smoke_load_ret
 * Purpose: verify the tight load-to-ret path used by function epilogues.
 * Flow:
 *   1. _start calls func.
 *   2. func saves ra, performs a nested call, reloads ra from the stack,
 *      and immediately returns with jalr x0, 0(ra).
 *   3. Success writes 1 to tohost; failure times out or writes 2.
 */

    .section .text.start
    .globl _start

_start:
    li      sp, 0x80
    jal     ra, func

pass:
    la      t0, tohost
    li      t1, 1
    sw      t1, 0(t0)
1:
    j       1b

func:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    jal     ra, nested
    lw      ra, 12(sp)
    jalr    zero, 0(ra)

nested:
    li      t2, 0x55
    ret

fail:
    la      t0, tohost
    li      t1, 2
    sw      t1, 0(t0)
2:
    j       2b
