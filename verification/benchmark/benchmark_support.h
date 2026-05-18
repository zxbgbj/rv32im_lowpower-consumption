#ifndef RV32IM_BENCHMARK_SUPPORT_H
#define RV32IM_BENCHMARK_SUPPORT_H

typedef unsigned int bench_u32;

#define BENCH_SIGNATURE_WORDS 64u
#define BENCH_SIGNATURE_MAGIC 0x42454e43u
#define BENCH_STATUS_PASS 0u
#define BENCH_SIG_STATUS_INDEX 1u
#define BENCH_SIG_BENCH_ID_INDEX 2u
#define BENCH_SIG_RESULT0_INDEX 5u
#define BENCH_SIG_CYCLE_LO_INDEX 9u
#define BENCH_SIG_CYCLE_HI_INDEX 10u

extern volatile bench_u32 tohost;
extern volatile bench_u32 fromhost;
extern volatile bench_u32 bench_signature[BENCH_SIGNATURE_WORDS];

void benchmark_init(void);
void benchmark_exit(int status);
void benchmark_write_signature(bench_u32 index, bench_u32 value);
bench_u32 benchmark_signature_capacity_words(void);

#endif
