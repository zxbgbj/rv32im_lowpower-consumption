#ifndef _RVMODEL_MACROS_H
#define _RVMODEL_MACROS_H

#define RVMODEL_DATA_SECTION \
  .pushsection .tohost,"aw",@progbits;              \
  .align 4; .global tohost; tohost: .word 0;        \
  .align 4; .global fromhost; fromhost: .word 0;    \
  .popsection;

##### STARTUP #####

// No DUT-specific boot sequence is required for the local ISA testbench.
//#define RVMODEL_BOOT

##### TERMINATION #####

#define RVMODEL_HALT_PASS  \
  li x1, 1                ;\
  la t0, tohost           ;\
write_tohost_pass:        ;\
  sw x1, 0(t0)            ;\
  sw x0, 4(t0)            ;\
self_loop_pass:           ;\
  j self_loop_pass        ;\

#define RVMODEL_HALT_FAIL  \
  li x1, 3                ;\
  la t0, tohost           ;\
write_tohost_fail:        ;\
  sw x1, 0(t0)            ;\
  sw x0, 4(t0)            ;\
self_loop_fail:           ;\
  j self_loop_fail        ;\

##### IO #####

// Console IO is optional for the local bench, so these expand to no-ops.
#define RVMODEL_IO_INIT(_R1, _R2, _R3)
#define RVMODEL_IO_WRITE_STR(_R1, _R2, _R3, _STR_PTR)

##### MACHINE TIMER / INTERRUPTS #####

#define RVMODEL_INTERRUPT_LATENCY 10
#define RVMODEL_TIMER_INT_SOON_DELAY 100

#define RVMODEL_SET_MEXT_INT(_R1, _R2)
#define RVMODEL_CLR_MEXT_INT(_R1, _R2)
#define RVMODEL_SET_MSW_INT(_R1, _R2)
#define RVMODEL_CLR_MSW_INT(_R1, _R2)

#define RVMODEL_SET_SEXT_INT(_R1, _R2)
#define RVMODEL_CLR_SEXT_INT(_R1, _R2)
#define RVMODEL_SET_SSW_INT(_R1, _R2)
#define RVMODEL_CLR_SSW_INT(_R1, _R2)

#endif // _RVMODEL_MACROS_H
