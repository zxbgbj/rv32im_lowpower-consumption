// Module: uart_tx.
// Role: lightweight UART transmitter for board-side status output.
// Interface: pulse `start` high for one cycle with `data` when `busy` is low.
module uart_tx #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer BAUD_RATE   = 115200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [7:0] data,
    output reg        tx,
    output reg        busy
);
    localparam integer BAUD_DIV = (CLK_FREQ_HZ + (BAUD_RATE / 2)) / BAUD_RATE;

    reg [15:0] baud_cnt;
    reg [3:0]  bit_idx;
    reg [9:0]  shift_reg;

    initial begin
        tx        = 1'b1;
        busy      = 1'b0;
        baud_cnt  = 16'd0;
        bit_idx   = 4'd0;
        shift_reg = 10'h3ff;
    end

    always @(posedge clk) begin
        if (rst) begin
            tx        <= 1'b1;
            busy      <= 1'b0;
            baud_cnt  <= 16'd0;
            bit_idx   <= 4'd0;
            shift_reg <= 10'h3ff;
        end else if (!busy) begin
            tx <= 1'b1;
            if (start) begin
                busy      <= 1'b1;
                baud_cnt  <= 16'd0;
                bit_idx   <= 4'd0;
                shift_reg <= {1'b1, data, 1'b0};
                tx        <= 1'b0;
            end
        end else begin
            if (baud_cnt == BAUD_DIV - 1) begin
                baud_cnt  <= 16'd0;
                shift_reg <= {1'b1, shift_reg[9:1]};
                tx        <= shift_reg[1];
                if (bit_idx == 4'd9) begin
                    busy    <= 1'b0;
                    bit_idx <= 4'd0;
                    tx      <= 1'b1;
                end else begin
                    bit_idx <= bit_idx + 4'd1;
                end
            end else begin
                baud_cnt <= baud_cnt + 16'd1;
            end
        end
    end
endmodule
