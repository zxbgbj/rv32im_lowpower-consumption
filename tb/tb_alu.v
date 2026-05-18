`timescale 1ns/1ps
// Testbench: tb_alu.
// Target DUT: alu.
// Coverage: arithmetic, logical, compare, and shift control codes.
// Pass rule: each operation must produce the expected 32-bit result.
module tb_alu;
    reg [3:0] alu_ctrl;
    reg [31:0] op_a;
    reg [31:0] op_b;
    wire [31:0] result;

    alu dut (.alu_ctrl(alu_ctrl), .op_a(op_a), .op_b(op_b), .result(result));

    initial begin
        alu_ctrl = 4'd0; op_a = 10; op_b = 3; #1; if (result !== 13) begin $display("FAIL ALU ADD"); $finish; end
        alu_ctrl = 4'd1; #1; if (result !== 7) begin $display("FAIL ALU SUB"); $finish; end
        alu_ctrl = 4'd2; op_a = 32'hf0; op_b = 32'hcc; #1; if (result !== 32'hc0) begin $display("FAIL ALU AND"); $finish; end
        alu_ctrl = 4'd3; #1; if (result !== 32'hfc) begin $display("FAIL ALU OR"); $finish; end
        alu_ctrl = 4'd4; #1; if (result !== 32'h3c) begin $display("FAIL ALU XOR"); $finish; end
        alu_ctrl = 4'd5; op_a = -1; op_b = 1; #1; if (result !== 1) begin $display("FAIL ALU SLT"); $finish; end
        alu_ctrl = 4'd6; op_a = 1; op_b = 2; #1; if (result !== 1) begin $display("FAIL ALU SLTU"); $finish; end
        alu_ctrl = 4'd7; op_a = 1; op_b = 4; #1; if (result !== 16) begin $display("FAIL ALU SLL"); $finish; end
        alu_ctrl = 4'd8; op_a = 16; op_b = 2; #1; if (result !== 4) begin $display("FAIL ALU SRL"); $finish; end
        alu_ctrl = 4'd9; op_a = 32'hfffffff0; op_b = 2; #1; if (result !== 32'hfffffffc) begin $display("FAIL ALU SRA"); $finish; end
        alu_ctrl = 4'd10; op_a = 0; op_b = 32'h12345678; #1; if (result !== 32'h12345678) begin $display("FAIL ALU PASS"); $finish; end
        $display("PASS tb_alu");
        $finish;
    end
endmodule
