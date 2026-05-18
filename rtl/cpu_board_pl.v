// Module: cpu_board_pl.
// Role: board-facing PL wrapper for benchmark execution, debug UART, and PS-visible status words.
module cpu_board_pl #(
    parameter IMEM_FILE = "",
    parameter DMEM_FILE = "",
    parameter BOARD_BENCH_ID = 8'h00,
    parameter CLK_FREQ_HZ = 80_000_000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        pl_uart_rx,
    output wire        pl_uart_tx,
    output wire        heartbeat_led,
    output reg  [31:0] board_status_word,
    output reg  [31:0] board_cycle_word
);
    localparam [31:0] TOHOST_ADDR       = 32'h0000_4000;
    localparam [31:0] SIG_STATUS_ADDR   = 32'h0000_4104;
    localparam [31:0] SIG_BENCHID_ADDR  = 32'h0000_4108;
    localparam [31:0] SIG_CYCLE_LO_ADDR = 32'h0000_4124;
    localparam [31:0] SIG_CYCLE_HI_ADDR = 32'h0000_4128;

    localparam [2:0] MSG_NONE  = 3'd0;
    localparam [2:0] MSG_BOOT  = 3'd1;
    localparam [2:0] MSG_PASS  = 3'd2;
    localparam [2:0] MSG_FAIL  = 3'd3;
    localparam [2:0] MSG_TRAP  = 3'd4;
    localparam [1:0] BOARD_RUNNING = 2'd0;
    localparam [1:0] BOARD_PASS    = 2'd1;
    localparam [1:0] BOARD_FAIL    = 2'd2;
    localparam [1:0] BOARD_TRAP    = 2'd3;

    wire [31:0] imem_addr;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [3:0]  dmem_we;
    wire        fetch_valid;
    wire [31:0] fetch_pc;
    wire        predict_taken;
    wire [31:0] predict_target;
    wire        redirect_valid;
    wire [31:0] redirect_pc;
    wire [31:0] instr32;
    wire [1:0]  instr_len;
    wire        instr_is_compressed;
    wire        issue_allow;
    wire        ex_busy;
    wire        ex_done;
    wire        trap_valid;
    wire [31:0] trap_pc;
    wire        issue_stall;
    wire        m_busy;
    wire        m_done;
    (* keep = "true" *) wire [31:0] activity_signature;
    (* keep = "true" *) reg  [31:0] activity_shadow;
    reg  [26:0] heartbeat_counter;
    reg  [1:0]  board_state;
    reg         trap_reported;
    reg         done_seen;
    reg         pass_seen;
    reg         fail_seen;
    reg  [31:0] latched_sig_status;

    reg         boot_pending;
    reg         msg_pending_valid;
    reg  [2:0]  msg_pending_kind;
    reg  [31:0] msg_pending_value;
    reg         msg_active;
    reg  [2:0]  msg_kind;
    reg  [4:0]  msg_index;
    reg  [31:0] msg_value;
    reg         uart_start;
    reg  [7:0]  uart_data;
    wire        uart_busy;
    wire [7:0]  msg_char;
    wire [4:0]  msg_last_index;
    wire        unused_pl_uart_rx;

    assign unused_pl_uart_rx = pl_uart_rx;
    assign activity_signature =
        imem_addr ^
        dmem_addr ^
        dmem_wdata ^
        {28'd0, dmem_we} ^
        fetch_pc ^
        predict_target ^
        redirect_pc ^
        instr32 ^
        trap_pc ^
        {20'd0, instr_len, instr_is_compressed, fetch_valid, predict_taken,
         redirect_valid, issue_allow, ex_busy, ex_done, trap_valid,
         issue_stall, m_busy, m_done};

    assign heartbeat_led =
        (board_state == BOARD_PASS) ? 1'b1 :
        ((board_state == BOARD_FAIL) || (board_state == BOARD_TRAP)) ? heartbeat_counter[22] :
        heartbeat_counter[24];

    assign msg_last_index =
        (msg_kind == MSG_BOOT) ? 5'd5 :
        ((msg_kind == MSG_PASS) || (msg_kind == MSG_FAIL) || (msg_kind == MSG_TRAP)) ? 5'd16 :
        5'd0;

    function [7:0] hex_ascii;
        input [3:0] nibble;
        begin
            if (nibble < 4'd10) begin
                hex_ascii = 8'h30 + nibble;
            end else begin
                hex_ascii = 8'h41 + (nibble - 4'd10);
            end
        end
    endfunction

    function [7:0] message_char;
        input [2:0] kind;
        input [4:0] index;
        input [31:0] value;
        begin
            message_char = 8'h20;
            case (kind)
                MSG_BOOT: begin
                    case (index)
                        5'd0: message_char = "B";
                        5'd1: message_char = "O";
                        5'd2: message_char = "O";
                        5'd3: message_char = "T";
                        5'd4: message_char = 8'h0d;
                        5'd5: message_char = 8'h0a;
                    endcase
                end
                MSG_PASS,
                MSG_FAIL,
                MSG_TRAP: begin
                    case (index)
                        5'd0:  message_char = (kind == MSG_PASS) ? "P" : ((kind == MSG_FAIL) ? "F" : "T");
                        5'd1:  message_char = (kind == MSG_PASS) ? "A" : ((kind == MSG_FAIL) ? "A" : "R");
                        5'd2:  message_char = (kind == MSG_PASS) ? "S" : ((kind == MSG_FAIL) ? "I" : "A");
                        5'd3:  message_char = (kind == MSG_PASS) ? "S" : ((kind == MSG_FAIL) ? "L" : "P");
                        5'd4:  message_char = 8'h20;
                        5'd5:  message_char = "0";
                        5'd6:  message_char = "x";
                        5'd7:  message_char = hex_ascii(value[31:28]);
                        5'd8:  message_char = hex_ascii(value[27:24]);
                        5'd9:  message_char = hex_ascii(value[23:20]);
                        5'd10: message_char = hex_ascii(value[19:16]);
                        5'd11: message_char = hex_ascii(value[15:12]);
                        5'd12: message_char = hex_ascii(value[11:8]);
                        5'd13: message_char = hex_ascii(value[7:4]);
                        5'd14: message_char = hex_ascii(value[3:0]);
                        5'd15: message_char = 8'h0d;
                        5'd16: message_char = 8'h0a;
                    endcase
                end
            endcase
        end
    endfunction

    assign msg_char = message_char(msg_kind, msg_index, msg_value);

    always @(posedge clk) begin
        if (rst) begin
            activity_shadow <= 32'd0;
            heartbeat_counter <= 27'd0;
            board_state <= BOARD_RUNNING;
            trap_reported <= 1'b0;
            done_seen <= 1'b0;
            pass_seen <= 1'b0;
            fail_seen <= 1'b0;
            latched_sig_status <= 32'd0;
            board_status_word <= {8'hA5, BOARD_BENCH_ID, 16'd0};
            board_cycle_word <= 32'd0;
            boot_pending <= 1'b1;
            msg_pending_valid <= 1'b0;
            msg_pending_kind <= MSG_NONE;
            msg_pending_value <= 32'd0;
            msg_active <= 1'b0;
            msg_kind <= MSG_NONE;
            msg_index <= 5'd0;
            msg_value <= 32'd0;
            uart_start <= 1'b0;
            uart_data <= 8'd0;
        end else begin
            activity_shadow <= activity_signature;
            heartbeat_counter <= heartbeat_counter + 27'd1;
            uart_start <= 1'b0;

            if ((|dmem_we) && (dmem_addr[31:2] == SIG_STATUS_ADDR[31:2])) begin
                latched_sig_status <= dmem_wdata;
            end
            if ((|dmem_we) && (dmem_addr[31:2] == SIG_CYCLE_LO_ADDR[31:2])) begin
                board_cycle_word <= dmem_wdata;
            end

            if ((|dmem_we) && (dmem_addr[31:2] == TOHOST_ADDR[31:2]) && (dmem_wdata != 32'd0)) begin
                done_seen <= 1'b1;
                if (dmem_wdata == 32'd1) begin
                    pass_seen <= 1'b1;
                    board_state <= BOARD_PASS;
                    msg_pending_kind <= MSG_PASS;
                end else begin
                    fail_seen <= 1'b1;
                    board_state <= BOARD_FAIL;
                    msg_pending_kind <= MSG_FAIL;
                end
                msg_pending_valid <= 1'b1;
                msg_pending_value <= dmem_wdata;
            end else if (trap_valid && !trap_reported) begin
                trap_reported <= 1'b1;
                board_state <= BOARD_TRAP;
                msg_pending_valid <= 1'b1;
                msg_pending_kind <= MSG_TRAP;
                msg_pending_value <= trap_pc;
            end

            board_status_word <= {
                8'hA5,
                BOARD_BENCH_ID,
                done_seen,
                pass_seen,
                fail_seen,
                trap_reported,
                4'd0,
                latched_sig_status[7:0]
            };

            if (!msg_active) begin
                if (boot_pending) begin
                    boot_pending <= 1'b0;
                    msg_active <= 1'b1;
                    msg_kind <= MSG_BOOT;
                    msg_index <= 5'd0;
                    msg_value <= 32'd0;
                end else if (msg_pending_valid) begin
                    msg_pending_valid <= 1'b0;
                    msg_active <= 1'b1;
                    msg_kind <= msg_pending_kind;
                    msg_index <= 5'd0;
                    msg_value <= msg_pending_value;
                end
            end else if (!uart_busy) begin
                uart_start <= 1'b1;
                uart_data <= msg_char;
                if (msg_index == msg_last_index) begin
                    msg_active <= 1'b0;
                    msg_kind <= MSG_NONE;
                    msg_index <= 5'd0;
                end else begin
                    msg_index <= msg_index + 5'd1;
                end
            end
        end
    end

    uart_tx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(115200)
    ) board_uart_tx_u (
        .clk(clk),
        .rst(rst),
        .start(uart_start),
        .data(uart_data),
        .tx(pl_uart_tx),
        .busy(uart_busy)
    );

    (* DONT_TOUCH = "TRUE", KEEP_HIERARCHY = "TRUE" *)
    cpu_top #(
        .IMEM_FILE(IMEM_FILE),
        .DMEM_FILE(DMEM_FILE)
    ) cpu_core_u (
        .clk(clk),
        .rst(rst),
        .imem_addr(imem_addr),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .fetch_valid(fetch_valid),
        .fetch_pc(fetch_pc),
        .predict_taken(predict_taken),
        .predict_target(predict_target),
        .redirect_valid(redirect_valid),
        .redirect_pc(redirect_pc),
        .instr32(instr32),
        .instr_len(instr_len),
        .instr_is_compressed(instr_is_compressed),
        .issue_allow(issue_allow),
        .ex_busy(ex_busy),
        .ex_done(ex_done),
        .trap_valid(trap_valid),
        .trap_pc(trap_pc),
        .issue_stall(issue_stall),
        .m_busy(m_busy),
        .m_done(m_done)
    );
endmodule
