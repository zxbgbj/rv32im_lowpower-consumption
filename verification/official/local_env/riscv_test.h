// Local environment header for adapting official riscv-tests sources
// to the small-address Harvard-memory verification platform used by
// rv32im_low-power.
//
// This environment intentionally keeps execution in M-mode and writes
// pass/fail directly to tohost, because the current CPU model focuses
// on ISA datapath/control validation rather than full official TVM
// privilege behavior.

#ifndef _LOCAL_ENV_RISCV_TEST_H
#define _LOCAL_ENV_RISCV_TEST_H

#define RVTEST_RV64U .macro init; .endm
#define RVTEST_RV64UF .macro init; .endm
#define RVTEST_RV64UV .macro init; .endm
#define RVTEST_RV64UVX .macro init; .endm

#define RVTEST_RV32U .macro init; .endm
#define RVTEST_RV32UF .macro init; .endm
#define RVTEST_RV32UV .macro init; .endm
#define RVTEST_RV32UVX .macro init; .endm

#define RVTEST_RV64M .macro init; .endm
#define RVTEST_RV64S .macro init; .endm
#define RVTEST_RV32M .macro init; .endm
#define RVTEST_RV32S .macro init; .endm

#define INIT_XREG       \
  li x1, 0;             \
  li x2, 0;             \
  li x3, 0;             \
  li x4, 0;             \
  li x5, 0;             \
  li x6, 0;             \
  li x7, 0;             \
  li x8, 0;             \
  li x9, 0;             \
  li x10, 0;            \
  li x11, 0;            \
  li x12, 0;            \
  li x13, 0;            \
  li x14, 0;            \
  li x15, 0;            \
  li x16, 0;            \
  li x17, 0;            \
  li x18, 0;            \
  li x19, 0;            \
  li x20, 0;            \
  li x21, 0;            \
  li x22, 0;            \
  li x23, 0;            \
  li x24, 0;            \
  li x25, 0;            \
  li x26, 0;            \
  li x27, 0;            \
  li x28, 0;            \
  li x29, 0;            \
  li x30, 0;            \
  li x31, 0;

#define TESTNUM gp

#define RVTEST_CODE_BEGIN \
        .section .text.init; \
        .align 4; \
        .globl _start; \
_start:; \
        INIT_XREG; \
        li TESTNUM, 0; \
        init;

#define RVTEST_CODE_END \
        unimp

#define RVTEST_PASS \
        fence; \
        li TESTNUM, 1; \
        la t5, tohost; \
        sw TESTNUM, 0(t5); \
1:      j 1b

#define RVTEST_FAIL \
        fence; \
1:      beqz TESTNUM, 1b; \
        sll TESTNUM, TESTNUM, 1; \
        ori TESTNUM, TESTNUM, 1; \
        la t5, tohost; \
        sw TESTNUM, 0(t5); \
2:      j 2b

#define EXTRA_DATA

#define RVTEST_DATA_BEGIN \
        EXTRA_DATA \
        .pushsection .tohost,"aw",@progbits; \
        .align 3; .global tohost; tohost: .dword 0; .size tohost, 8; \
        .align 3; .global fromhost; fromhost: .dword 0; .size fromhost, 8; \
        .popsection; \
        .align 4; .global begin_signature; begin_signature:

#define RVTEST_DATA_END \
        .align 4; .global end_signature; end_signature:

#endif
