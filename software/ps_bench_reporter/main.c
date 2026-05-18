#include "xgpiops.h"
#include "xparameters.h"
#include "xuartps.h"
#include "xil_printf.h"

#define STATUS_MAGIC_MASK      0xFF000000u
#define STATUS_MAGIC_VALUE     0xA5000000u
#define STATUS_BENCH_SHIFT     16
#define STATUS_DONE_MASK       0x00008000u
#define STATUS_PASS_MASK       0x00004000u
#define STATUS_FAIL_MASK       0x00002000u
#define STATUS_TRAP_MASK       0x00001000u
#define STATUS_CODE_MASK       0x000000FFu

#define BENCH_COREMARK         0x01u
#define BENCH_MATRIX           0x02u

#define GPIO_BANK_STATUS       2u
#define GPIO_BANK_CYCLES       3u
#define GPIO_TIMEOUT_LOOPS     50000000u

#if defined(XPAR_XUARTPS_1_DEVICE_ID)
#define BENCH_UART_DEVICE_ID   XPAR_XUARTPS_1_DEVICE_ID
#elif defined(XPAR_XUARTPS_0_DEVICE_ID)
#define BENCH_UART_DEVICE_ID   XPAR_XUARTPS_0_DEVICE_ID
#else
#error "No XUartPs device ID found in xparameters.h"
#endif

static XGpioPs Gpio;
static XUartPs Uart;

static int init_gpio(void) {
    XGpioPs_Config *cfg;
    cfg = XGpioPs_LookupConfig(XPAR_XGPIOPS_0_DEVICE_ID);
    if (cfg == 0) {
        return XST_FAILURE;
    }
    return XGpioPs_CfgInitialize(&Gpio, cfg, cfg->BaseAddr);
}

static int init_uart(void) {
    XUartPs_Config *cfg;
    int status;

    cfg = XUartPs_LookupConfig(BENCH_UART_DEVICE_ID);
    if (cfg == 0) {
        return XST_FAILURE;
    }

    status = XUartPs_CfgInitialize(&Uart, cfg, cfg->BaseAddress);
    if (status != XST_SUCCESS) {
        return status;
    }

    status = XUartPs_SetBaudRate(&Uart, 115200);
    if (status != XST_SUCCESS) {
        return status;
    }

    return XST_SUCCESS;
}

static const char *bench_name(unsigned int bench_id) {
    if (bench_id == BENCH_COREMARK) {
        return "COREMARK";
    }
    if (bench_id == BENCH_MATRIX) {
        return "MATRIX";
    }
    return "UNKNOWN";
}

int main(void) {
    unsigned int loops;
    u32 status_word;
    u32 cycle_word;
    unsigned int bench_id;

    if (init_uart() != XST_SUCCESS) {
        return 1;
    }
    if (init_gpio() != XST_SUCCESS) {
        xil_printf("BOOT GPIO_INIT_FAIL\r\n");
        return 1;
    }

    xil_printf("BOOT PS+PL BENCH\r\n");

    for (loops = 0u; loops < GPIO_TIMEOUT_LOOPS; ++loops) {
        status_word = XGpioPs_Read(&Gpio, GPIO_BANK_STATUS);
        if ((status_word & STATUS_MAGIC_MASK) == STATUS_MAGIC_VALUE &&
            (status_word & STATUS_DONE_MASK) != 0u) {
            break;
        }
    }

    status_word = XGpioPs_Read(&Gpio, GPIO_BANK_STATUS);
    cycle_word = XGpioPs_Read(&Gpio, GPIO_BANK_CYCLES);
    bench_id = (status_word >> STATUS_BENCH_SHIFT) & 0xFFu;

    xil_printf("BENCH %s\r\n", bench_name(bench_id));
    xil_printf("CYCLES %lu\r\n", (unsigned long)cycle_word);
    xil_printf("STATUS 0x%08lx\r\n", (unsigned long)status_word);

    if ((status_word & STATUS_PASS_MASK) != 0u) {
        xil_printf("PASS %s %lu\r\n", bench_name(bench_id), (unsigned long)cycle_word);
    } else if ((status_word & STATUS_FAIL_MASK) != 0u) {
        xil_printf("FAIL %s code=0x%02lx\r\n", bench_name(bench_id), (unsigned long)(status_word & STATUS_CODE_MASK));
    } else if ((status_word & STATUS_TRAP_MASK) != 0u) {
        xil_printf("TRAP %s\r\n", bench_name(bench_id));
    } else {
        xil_printf("TIMEOUT OR INVALID STATUS\r\n");
    }

    while (1) {
    }

    return 0;
}
