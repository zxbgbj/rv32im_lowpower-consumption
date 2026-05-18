#include "benchmark_support.h"

volatile bench_u32 tohost __attribute__((section(".tohost"), used)) = 0u;
volatile bench_u32 fromhost __attribute__((section(".fromhost"), used)) = 0u;
volatile bench_u32 bench_signature[BENCH_SIGNATURE_WORDS] __attribute__((section(".signature"), used));

static unsigned long long benchmark_read_cycle64(void) {
    bench_u32 hi0;
    bench_u32 lo;
    bench_u32 hi1;

    do {
        __asm__ volatile ("rdcycleh %0" : "=r"(hi0));
        __asm__ volatile ("rdcycle %0" : "=r"(lo));
        __asm__ volatile ("rdcycleh %0" : "=r"(hi1));
    } while (hi0 != hi1);

    return (((unsigned long long)hi0) << 32) | (unsigned long long)lo;
}

static bench_u32 bench_fail_code(int status) {
    if (status < 0) {
        return 2u;
    }
    return (bench_u32)status + 2u;
}

void benchmark_write_signature(bench_u32 index, bench_u32 value) {
    if (index < BENCH_SIGNATURE_WORDS) {
        bench_signature[index] = value;
    }
}

bench_u32 benchmark_signature_capacity_words(void) {
    return BENCH_SIGNATURE_WORDS;
}

void benchmark_init(void) {
    bench_u32 idx;

    tohost = 0u;
    fromhost = 0u;
    for (idx = 0u; idx < BENCH_SIGNATURE_WORDS; idx++) {
        bench_signature[idx] = 0u;
    }

    bench_signature[0] = BENCH_SIGNATURE_MAGIC;
    bench_signature[1] = 0xffffffffu;
    bench_signature[BENCH_SIG_CYCLE_LO_INDEX] = 0u;
    bench_signature[BENCH_SIG_CYCLE_HI_INDEX] = 0u;
}

void benchmark_exit(int status) {
    unsigned long long cycles;

    cycles = benchmark_read_cycle64();
    bench_signature[1] = (bench_u32)status;
    bench_signature[BENCH_SIG_CYCLE_LO_INDEX] = (bench_u32)cycles;
    bench_signature[BENCH_SIG_CYCLE_HI_INDEX] = (bench_u32)(cycles >> 32);
    if (status == 0) {
        tohost = 1u;
    } else {
        tohost = bench_fail_code(status);
    }
}
