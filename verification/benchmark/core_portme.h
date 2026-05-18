#ifndef CORE_PORTME_H
#define CORE_PORTME_H

#include <stddef.h>
#include <stdint.h>

typedef signed short   ee_s16;
typedef unsigned short ee_u16;
typedef signed int     ee_s32;
typedef unsigned char  ee_u8;
typedef unsigned int   ee_u32;
typedef size_t         ee_size_t;
typedef uintptr_t      ee_ptr_int;

#define NULL ((void *)0)

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

#define COREMARK_STRINGIFY_IMPL(x) #x
#define COREMARK_STRINGIFY(x) COREMARK_STRINGIFY_IMPL(x)

#ifndef COMPILER_FLAGS
#ifdef FLAGS_STR
#define COMPILER_FLAGS COREMARK_STRINGIFY(FLAGS_STR)
#else
#define COMPILER_FLAGS "rv32im"
#endif
#endif

#ifndef MEM_LOCATION
#define MEM_LOCATION "STATIC"
#endif

#ifndef SEED_METHOD
#define SEED_METHOD SEED_VOLATILE
#endif

#ifndef MEM_METHOD
#define MEM_METHOD MEM_STATIC
#endif

#ifndef MULTITHREAD
#define MULTITHREAD 1
#define USE_PTHREAD 0
#define USE_FORK    0
#define USE_SOCKET  0
#endif

#ifndef MAIN_HAS_NOARGC
#define MAIN_HAS_NOARGC 1
#endif

#ifndef MAIN_HAS_NORETURN
#define MAIN_HAS_NORETURN 0
#endif

#define align_mem(x) (void *)(4 + (((ee_ptr_int)(x)-1) & ~3))

#define CORETIMETYPE ee_u32
typedef ee_u32 CORE_TICKS;

#define EE_TICKS_PER_SEC 100000000u

extern ee_u32 default_num_contexts;

typedef struct CORE_PORTABLE_S
{
    ee_u8 portable_id;
} core_portable;

void portable_init(core_portable *p, int *argc, char *argv[]);
void portable_fini(core_portable *p);

void       start_time(void);
void       stop_time(void);
CORE_TICKS get_time(void);
ee_u32     time_in_secs(CORE_TICKS ticks);

int   ee_printf(const char *fmt, ...);
void *portable_malloc(ee_size_t size);
void  portable_free(void *p);

#endif
