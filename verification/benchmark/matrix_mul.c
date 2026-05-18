#include "benchmark_support.h"

#ifndef MATRIX_DIM
#define MATRIX_DIM 16
#endif

#ifndef MATRIX_ITERATIONS
#define MATRIX_ITERATIONS 12
#endif

#ifndef MATRIX_EXPECT_CHECKSUM
#define MATRIX_EXPECT_CHECKSUM 0x67209c58u
#endif

#define MATRIX_BENCH_ID 0x4d415458u

static bench_u32 mat_a[MATRIX_DIM][MATRIX_DIM];
static bench_u32 mat_b[MATRIX_DIM][MATRIX_DIM];
static bench_u32 mat_c[MATRIX_DIM][MATRIX_DIM];

static void matrix_init_inputs(void) {
    bench_u32 i;
    bench_u32 j;

    for (i = 0u; i < MATRIX_DIM; i++) {
        for (j = 0u; j < MATRIX_DIM; j++) {
            mat_a[i][j] = ((i * 17u) + (j * 3u) + 1u) & 0xffu;
            mat_b[i][j] = ((i * 5u) + (j * 11u) + 7u) & 0xffu;
            mat_c[i][j] = 0u;
        }
    }
}

static void matrix_kernel(void) {
    bench_u32 i;
    bench_u32 j;
    bench_u32 k;

    for (i = 0u; i < MATRIX_DIM; i++) {
        for (j = 0u; j < MATRIX_DIM; j++) {
            bench_u32 sum = 0u;
            for (k = 0u; k < MATRIX_DIM; k++) {
                sum += mat_a[i][k] * mat_b[k][j];
            }
            mat_c[i][j] = sum;
        }
    }
}

static bench_u32 matrix_checksum(void) {
    bench_u32 i;
    bench_u32 j;
    bench_u32 checksum = 0u;

    for (i = 0u; i < MATRIX_DIM; i++) {
        for (j = 0u; j < MATRIX_DIM; j++) {
            checksum += mat_c[i][j] * ((i + 1u) * 17u + (j + 1u) * 13u);
        }
    }
    return checksum;
}

int main(void) {
    bench_u32 iter;
    bench_u32 checksum;

    matrix_init_inputs();
    for (iter = 0u; iter < MATRIX_ITERATIONS; iter++) {
        matrix_kernel();
        mat_a[iter % MATRIX_DIM][(iter * 3u) % MATRIX_DIM] ^= (iter + 1u);
        mat_b[(iter * 5u) % MATRIX_DIM][iter % MATRIX_DIM] += (iter + 3u);
    }

    checksum = matrix_checksum();

    benchmark_write_signature(2u, MATRIX_BENCH_ID);
    benchmark_write_signature(3u, MATRIX_DIM);
    benchmark_write_signature(4u, MATRIX_ITERATIONS);
    benchmark_write_signature(5u, checksum);
    benchmark_write_signature(6u, mat_c[0][0]);
    benchmark_write_signature(7u, mat_c[MATRIX_DIM - 1u][MATRIX_DIM - 1u]);

    if (checksum != MATRIX_EXPECT_CHECKSUM) {
        benchmark_write_signature(8u, MATRIX_EXPECT_CHECKSUM);
        return 1;
    }

    return 0;
}
