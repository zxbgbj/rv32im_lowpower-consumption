#ifndef CORE_PORTME_H
#define CORE_PORTME_H

#include <stddef.h>
#include <stdint.h>

typedef uint8_t ee_u8;
typedef int8_t ee_s8;
typedef uint16_t ee_u16;
typedef int16_t ee_s16;
typedef uint32_t ee_u32;
typedef int32_t ee_s32;
typedef uintptr_t ee_ptr_int;
typedef size_t ee_size_t;

typedef ee_u32 CORE_TICKS;
typedef ee_u32 CORETIMETYPE;
typedef double secs_ret;

typedef struct core_portable_s {
    ee_u8 portable_id;
} core_portable;

#ifndef HAS_FLOAT
#define HAS_FLOAT 0
#endif

#ifndef HAS_TIME_H
#define HAS_TIME_H 0
#endif

#ifndef USE_CLOCK
#define USE_CLOCK 0
#endif

#ifndef HAS_STDIO
#define HAS_STDIO 0
#endif

#ifndef HAS_PRINTF
#define HAS_PRINTF 0
#endif

#ifndef COMPILER_VERSION
#define COMPILER_VERSION "riscv-none-elf-gcc"
#endif

#ifndef COMPILER_FLAGS
#define COMPILER_FLAGS FLAGS_STR
#endif

#ifndef MEM_LOCATION
#define MEM_LOCATION "STATIC"
#endif

#define MAIN_HAS_NOARGC 1

void portable_init(core_portable *p, int *argc, char *argv[]);
void portable_fini(core_portable *p);
void start_time(void);
void stop_time(void);
CORE_TICKS get_time(void);
secs_ret time_in_secs(CORE_TICKS ticks);
int ee_printf(const char *fmt, ...);

#endif
