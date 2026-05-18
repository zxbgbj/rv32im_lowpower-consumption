`timescale 1ns/1ps
// Testbench: tb_imm_gen.
// Target DUT: imm_gen.
// Coverage: I, S, B, U, and J immediate decode cases.
// Pass rule: generated immediates must match the sign-extension and bit-placement rules.
module tb_imm_gen;
    reg [31:0] instr;
    wire [31:0] imm;

    imm_gen dut (.instr(instr), .imm(imm));

    initial begin
        instr = 32'h00500093; #1; if (imm !== 32'd5) begin $display("FAIL IMM I"); $finish; end
        instr = 32'h00202023; #1; if (imm !== 32'd0) begin $display("FAIL IMM S"); $finish; end
        instr = 32'h00209463; #1; if (imm !== 32'd8) begin $display("FAIL IMM B"); $finish; end
        instr = 32'h123450b7; #1; if (imm !== 32'h12345000) begin $display("FAIL IMM U"); $finish; end
        instr = 32'h0080006f; #1; if (imm !== 32'd8) begin $display("FAIL IMM J"); $finish; end
        $display("PASS tb_imm_gen");
        $finish;
    end
endmodule
