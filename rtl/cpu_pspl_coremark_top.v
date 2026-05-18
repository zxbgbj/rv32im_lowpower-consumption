module cpu_pspl_coremark_top (
    inout  wire [14:0] DDR_addr,
    inout  wire [2:0]  DDR_ba,
    inout  wire        DDR_cas_n,
    inout  wire        DDR_ck_n,
    inout  wire        DDR_ck_p,
    inout  wire        DDR_cke,
    inout  wire        DDR_cs_n,
    inout  wire [3:0]  DDR_dm,
    inout  wire [31:0] DDR_dq,
    inout  wire [3:0]  DDR_dqs_n,
    inout  wire [3:0]  DDR_dqs_p,
    inout  wire        DDR_odt,
    inout  wire        DDR_ras_n,
    inout  wire        DDR_reset_n,
    inout  wire        DDR_we_n,
    inout  wire        FIXED_IO_ddr_vrn,
    inout  wire        FIXED_IO_ddr_vrp,
    inout  wire [53:0] FIXED_IO_mio,
    inout  wire        FIXED_IO_ps_clk,
    inout  wire        FIXED_IO_ps_porb,
    inout  wire        FIXED_IO_ps_srstb,
    input  wire        rst,
    input  wire        pl_uart_rx,
    output wire        pl_uart_tx,
    output wire        heartbeat_led
);
    wire        fclk_clk0;
    wire        fclk_reset0_n;
    wire [31:0] board_status_word;
    wire [31:0] board_cycle_word;
    wire [63:0] gpio_i;
    wire [63:0] gpio_o_unused;
    wire [63:0] gpio_t_unused;
    wire        ext_reset_active = ~rst;
    wire        pl_rst = ext_reset_active | (~fclk_reset0_n);

    assign gpio_i = {board_cycle_word, board_status_word};

    processing_system7_0 ps7_u (
        .DDR_Addr(DDR_addr),
        .DDR_BankAddr(DDR_ba),
        .DDR_CAS_n(DDR_cas_n),
        .DDR_CKE(DDR_cke),
        .DDR_CS_n(DDR_cs_n),
        .DDR_Clk(DDR_ck_p),
        .DDR_Clk_n(DDR_ck_n),
        .DDR_DM(DDR_dm),
        .DDR_DQ(DDR_dq),
        .DDR_DQS(DDR_dqs_p),
        .DDR_DQS_n(DDR_dqs_n),
        .DDR_DRSTB(DDR_reset_n),
        .DDR_ODT(DDR_odt),
        .DDR_RAS_n(DDR_ras_n),
        .DDR_VRN(FIXED_IO_ddr_vrn),
        .DDR_VRP(FIXED_IO_ddr_vrp),
        .DDR_WEB(DDR_we_n),
        .FCLK_CLK0(fclk_clk0),
        .FCLK_RESET0_N(fclk_reset0_n),
        .GPIO_I(gpio_i),
        .GPIO_O(gpio_o_unused),
        .GPIO_T(gpio_t_unused),
        .MIO(FIXED_IO_mio),
        .PS_CLK(FIXED_IO_ps_clk),
        .PS_PORB(FIXED_IO_ps_porb),
        .PS_SRSTB(FIXED_IO_ps_srstb)
    );

    cpu_board_coremark_pl pl_core_u (
        .clk(fclk_clk0),
        .rst(pl_rst),
        .pl_uart_rx(pl_uart_rx),
        .pl_uart_tx(pl_uart_tx),
        .heartbeat_led(heartbeat_led),
        .board_status_word(board_status_word),
        .board_cycle_word(board_cycle_word)
    );
endmodule
