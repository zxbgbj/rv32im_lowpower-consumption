#include "benchmark_support.h"
#include "coremark.h"

static CORE_TICKS start_ticks;
static CORE_TICKS stop_ticks;

void portable_init(core_portable *p, int *argc, char *argv[]) {
    (void)argc;
    (void)argv;
    p->portable_id = 1u;
    start_ticks = 0u;
    stop_ticks = 1u;
}

void portable_fini(core_portable *p) {
    p->portable_id = 0u;
}

void start_time(void) {
    start_ticks = 0u;
}

void stop_time(void) {
    stop_ticks = 1u;
}

CORE_TICKS get_time(void) {
    return stop_ticks - start_ticks;
}

secs_ret time_in_secs(CORE_TICKS ticks) {
    return (secs_ret)ticks;
}

int ee_printf(const char *fmt, ...) {
    (void)fmt;
    return 0;
}
