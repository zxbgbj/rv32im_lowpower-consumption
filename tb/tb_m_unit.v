`timescale 1ns/1ps
// Testbench: tb_m_unit.
// Target DUT: m_unit.
// Coverage: all RV32M operations, enable gating, divide-by-zero handling, and signed overflow corner cases.
// Pass rule: result, busy, and done behavior must match the directed multicycle operation scenarios.
module tb_m_unit;
    reg clk;
    reg rst;
    reg enable;
    reg start;
    reg [2:0] op;
    reg [31:0] lhs;
    reg [31:0] rhs;
    wire busy;
    wire done;
    wire result_valid;
    wire [31:0] result;

    m_unit dut (
        .clk(clk), .rst(rst), .enable(enable), .start(start), .op(op), .lhs(lhs), .rhs(rhs),
        .busy(busy), .done(done), .result_valid(result_valid), .result(result)
    );
    always #5 clk = ~clk;

    task run_check;
        input [2:0]  op_i;
        input [31:0] lhs_i;
        input [31:0] rhs_i;
        input [31:0] exp_i;
        input [255:0] name;
        begin
            @(negedge clk);
            op = op_i; lhs = lhs_i; rhs = rhs_i; start = 1'b1;
            @(negedge clk);
            start = 1'b0;
            wait(done === 1'b1);
            #1;
            if (!result_valid || result !== exp_i) begin
                $display("FAIL MUNIT %s got=%08x exp=%08x", name, result, exp_i);
                $finish;
            end
            @(negedge clk);
        end
    endtask

    initial begin
        clk = 0; rst = 1; enable = 1; start = 0; op = 0; lhs = 0; rhs = 0;
        #12; rst = 0;

        enable = 0;
        @(negedge clk);
        start = 1'b1; op = 3'd0; lhs = 32'd3; rhs = 32'd4;
        @(negedge clk);
        start = 1'b0;
        #1;
        if (busy !== 1'b0) begin $display("FAIL MUNIT should stay idle when disabled"); $finish; end
        enable = 1;

        run_check(3'd0, 32'd7, 32'd6, 32'd42, "MUL");
        run_check(3'd1, 32'hffff_fff8, 32'd6, 32'hffff_ffff, "MULH");
        run_check(3'd2, 32'hffff_fff8, 32'd6, 32'hffff_ffff, "MULHSU");
        run_check(3'd3, 32'd7, 32'd6, 32'd0, "MULHU");
        run_check(3'd4, 32'd100, 32'd7, 32'd14, "DIV");
        run_check(3'd5, 32'd100, 32'd7, 32'd14, "DIVU");
        run_check(3'd6, 32'd100, 32'd7, 32'd2, "REM");
        run_check(3'd7, 32'd100, 32'd7, 32'd2, "REMU");
        run_check(3'd4, 32'd100, 32'd0, 32'hffff_ffff, "DIV by zero");
        run_check(3'd6, 32'd100, 32'd0, 32'd100, "REM by zero");
        run_check(3'd4, 32'h8000_0000, 32'hffff_ffff, 32'h8000_0000, "DIV overflow");
        run_check(3'd6, 32'h8000_0000, 32'hffff_ffff, 32'd0, "REM overflow");
        $display("PASS tb_m_unit");
        $finish;
    end
endmodule
