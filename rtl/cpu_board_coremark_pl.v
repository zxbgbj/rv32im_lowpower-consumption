module cpu_board_coremark_pl (
    input  wire        clk,
    input  wire        rst,
    input  wire        pl_uart_rx,
    output wire        pl_uart_tx,
    output wire        heartbeat_led,
    output wire [31:0] board_status_word,
    output wire [31:0] board_cycle_word
);
    cpu_board_pl #(
        .IMEM_FILE("D:/Codex project/RISC-V CPU/rv32im_low_power_v5/verification/generated/board_coremark.imem.hex"),
        .DMEM_FILE("D:/Codex project/RISC-V CPU/rv32im_low_power_v5/verification/generated/board_coremark.dmem.hex"),
        .BOARD_BENCH_ID(8'h01),
        .CLK_FREQ_HZ(80_000_000)
    ) u_board_pl (
        .clk(clk),
        .rst(rst),
        .pl_uart_rx(pl_uart_rx),
        .pl_uart_tx(pl_uart_tx),
        .heartbeat_led(heartbeat_led),
        .board_status_word(board_status_word),
        .board_cycle_word(board_cycle_word)
    );
endmodule
