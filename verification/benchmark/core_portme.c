#include "benchmark_support.h"
#include "coremark.h"

volatile ee_s32 seed1_volatile = 0;
volatile ee_s32 seed2_volatile = 0;
volatile ee_s32 seed3_volatile = 0x66;
volatile ee_s32 seed4_volatile = ITERATIONS;
volatile ee_s32 seed5_volatile = 0;

ee_u32 default_num_contexts = 1u;

static unsigned long long start_cycle;
static unsigned long long stop_cycle;

static unsigned long long read_cycle64(void) {
    ee_u32 hi0;
    ee_u32 lo;
    ee_u32 hi1;

    do {
        __asm__ volatile ("rdcycleh %0" : "=r"(hi0));
        __asm__ volatile ("rdcycle %0" : "=r"(lo));
        __asm__ volatile ("rdcycleh %0" : "=r"(hi1));
    } while (hi0 != hi1);

    return (((unsigned long long)hi0) << 32) | (unsigned long long)lo;
}

void start_time(void) {
    start_cycle = read_cycle64();
}

void stop_time(void) {
    stop_cycle = read_cycle64();
}

CORE_TICKS get_time(void) {
    return (CORE_TICKS)(stop_cycle - start_cycle);
}

ee_u32 time_in_secs(CORE_TICKS ticks) {
    return ticks / EE_TICKS_PER_SEC;
}

int ee_printf(const char *fmt, ...) {
    (void)fmt;
    return 0;
}

void *portable_malloc(ee_size_t size) {
    static ee_u8 memblock[TOTAL_DATA_SIZE + 32];

    if (size > (ee_size_t)(TOTAL_DATA_SIZE + 32)) {
        return NULL;
    }

    return memblock;
}

void portable_free(void *p) {
    (void)p;
}

void portable_init(core_portable *p, int *argc, char *argv[]) {
    (void)argc;
    (void)argv;

    if (sizeof(ee_ptr_int) != sizeof(ee_u8 *)) {
        benchmark_write_signature(30u, 0xdead0001u);
    }
    if (sizeof(ee_u32) != 4u) {
        benchmark_write_signature(31u, 0xdead0002u);
    }

    p->portable_id = 1u;
    start_cycle = 0ull;
    stop_cycle = 0ull;
    benchmark_write_signature(BENCH_SIG_BENCH_ID_INDEX, 0x434f5245u);
}

void portable_fini(core_portable *p) {
    p->portable_id = 0u;
    benchmark_write_signature(20u, (bench_u32)get_time());
    benchmark_write_signature(21u, (bench_u32)default_num_contexts);
    benchmark_write_signature(22u, (bench_u32)seed4_volatile);
}
