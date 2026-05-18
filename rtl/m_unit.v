// Module: m_unit.
// Role: RV32M execution unit with DSP-friendly multiply path and iterative divide/remainder path.
// Key ports: enable, start, m_op [2:0], lhs [31:0], rhs [31:0], result [31:0], busy, done.
// Connections: launched from EX stage, holds the pipeline through cpu_top when busy, and returns results into the normal write-back path.
module m_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire        start,
    input  wire [2:0]  op,
    input  wire [31:0] lhs,
    input  wire [31:0] rhs,
    output reg         busy,
    output reg         done,
    output reg         result_valid,
    output reg  [31:0] result
);
    localparam OP_MUL    = 3'd0;
    localparam OP_MULH   = 3'd1;
    localparam OP_MULHSU = 3'd2;
    localparam OP_MULHU  = 3'd3;
    localparam OP_DIV    = 3'd4;
    localparam OP_DIVU   = 3'd5;
    localparam OP_REM    = 3'd6;
    localparam OP_REMU   = 3'd7;

    reg [2:0]  op_q;
    reg [31:0] lhs_q;
    reg [31:0] rhs_q;
    reg [5:0]  count;

    reg        div_mode_q;
    reg        div_signed_q;
    reg        div_is_rem_q;
    reg        div_special_q;
    reg        quotient_neg_q;
    reg        remainder_neg_q;
    reg [31:0] divisor_q;
    reg [31:0] quotient_q;
    reg [32:0] remainder_q;
    reg [31:0] special_result_q;

    reg [32:0] rem_work;
    reg [31:0] quot_work;
    reg [31:0] quot_final;
    reg [31:0] rem_final;

    (* use_dsp = "yes" *) wire [63:0] mul_signed   = $signed(lhs_q) * $signed(rhs_q);
    (* use_dsp = "yes" *) wire [63:0] mul_unsigned = lhs_q * rhs_q;
    (* use_dsp = "yes" *) wire [65:0] mul_mixed    = $signed({lhs_q[31], lhs_q}) * $signed({1'b0, rhs_q});

    function [31:0] abs32;
        input [31:0] value;
        begin
            abs32 = value[31] ? (~value + 32'd1) : value;
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0;
            done <= 1'b0;
            result_valid <= 1'b0;
            result <= 32'd0;
            count <= 6'd0;
            op_q <= 3'd0;
            lhs_q <= 32'd0;
            rhs_q <= 32'd0;
            div_mode_q <= 1'b0;
            div_signed_q <= 1'b0;
            div_is_rem_q <= 1'b0;
            div_special_q <= 1'b0;
            quotient_neg_q <= 1'b0;
            remainder_neg_q <= 1'b0;
            divisor_q <= 32'd0;
            quotient_q <= 32'd0;
            remainder_q <= 33'd0;
            special_result_q <= 32'd0;
        end else begin
            done <= 1'b0;
            result_valid <= 1'b0;

            if (enable) begin
                if (start && !busy) begin
                    op_q <= op;
                    lhs_q <= lhs;
                    rhs_q <= rhs;

                    if (op <= OP_MULHU) begin
                        busy <= 1'b1;
                        count <= 6'd1;
                        div_mode_q <= 1'b0;
                        div_signed_q <= 1'b0;
                        div_is_rem_q <= 1'b0;
                        div_special_q <= 1'b0;
                    end else begin
                        busy <= 1'b1;
                        div_mode_q <= 1'b1;
                        div_signed_q <= (op == OP_DIV) || (op == OP_REM);
                        div_is_rem_q <= (op == OP_REM) || (op == OP_REMU);
                        quotient_neg_q <= ((op == OP_DIV) || (op == OP_REM)) && (lhs[31] ^ rhs[31]);
                        remainder_neg_q <= ((op == OP_DIV) || (op == OP_REM)) && lhs[31];
                        remainder_q <= 33'd0;

                        if (rhs == 32'd0) begin
                            div_special_q <= 1'b1;
                            count <= 6'd2;
                            special_result_q <= ((op == OP_DIV) || (op == OP_DIVU)) ? 32'hffff_ffff : lhs;
                            divisor_q <= 32'd0;
                            quotient_q <= 32'd0;
                        end else if (((op == OP_DIV) || (op == OP_REM)) && (lhs == 32'h8000_0000) && (rhs == 32'hffff_ffff)) begin
                            div_special_q <= 1'b1;
                            count <= 6'd2;
                            special_result_q <= (op == OP_DIV) ? 32'h8000_0000 : 32'd0;
                            divisor_q <= 32'd0;
                            quotient_q <= 32'd0;
                        end else begin
                            div_special_q <= 1'b0;
                            count <= 6'd32;
                            divisor_q <= (((op == OP_DIV) || (op == OP_REM)) ? abs32(rhs) : rhs);
                            quotient_q <= (((op == OP_DIV) || (op == OP_REM)) ? abs32(lhs) : lhs);
                        end
                    end
                end else if (busy) begin
                    rem_work = remainder_q;
                    quot_work = quotient_q;
                    quot_final = quotient_q;
                    rem_final = remainder_q[31:0];

                    if (div_mode_q && !div_special_q) begin
                        rem_work = {remainder_q[31:0], quotient_q[31]};
                        quot_work = {quotient_q[30:0], 1'b0};
                        if (rem_work >= {1'b0, divisor_q}) begin
                            rem_work = rem_work - {1'b0, divisor_q};
                            quot_work[0] = 1'b1;
                        end
                        remainder_q <= rem_work;
                        quotient_q <= quot_work;
                        quot_final = quot_work;
                        rem_final = rem_work[31:0];
                    end

                    if (count != 6'd0) begin
                        count <= count - 6'd1;
                    end

                    if (count == 6'd1) begin
                        busy <= 1'b0;
                        done <= 1'b1;
                        result_valid <= 1'b1;
                        case (op_q)
                            OP_MUL:    result <= mul_signed[31:0];
                            OP_MULH:   result <= mul_signed[63:32];
                            OP_MULHSU: result <= mul_mixed[63:32];
                            OP_MULHU:  result <= mul_unsigned[63:32];
                            OP_DIV,
                            OP_DIVU,
                            OP_REM,
                            OP_REMU: begin
                                if (div_special_q) begin
                                    result <= special_result_q;
                                end else if (div_is_rem_q) begin
                                    result <= remainder_neg_q ? (~rem_final + 32'd1) : rem_final;
                                end else begin
                                    result <= quotient_neg_q ? (~quot_final + 32'd1) : quot_final;
                                end
                            end
                            default: result <= 32'd0;
                        endcase
                    end
                end
            end
        end
    end
endmodule
