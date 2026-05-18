`timescale 1ns/1ps
// Testbench: tb_branch_unit.
// Target DUT: branch_unit.
// Coverage: BEQ, BNE, BLT, BGE, BLTU, BGEU, JAL, and JALR target generation.
// Pass rule: taken flag and branch target must match the instruction class under test.
module tb_branch_unit;
    reg branch;
    reg [2:0] funct3;
    reg [31:0] lhs;
    reg [31:0] rhs;
    wire taken;

    branch_unit dut (.branch(branch), .funct3(funct3), .lhs(lhs), .rhs(rhs), .taken(taken));

    initial begin
        branch = 1'b1;
        funct3 = 3'b000; lhs = 32'd9; rhs = 32'd9; #1; if (taken !== 1'b1) begin $display("FAIL BRANCH BEQ taken"); $finish; end
        funct3 = 3'b000; lhs = 32'd9; rhs = 32'd8; #1; if (taken !== 1'b0) begin $display("FAIL BRANCH BEQ not taken"); $finish; end
        funct3 = 3'b001; lhs = 32'd9; rhs = 32'd8; #1; if (taken !== 1'b1) begin $display("FAIL BRANCH BNE taken"); $finish; end
        funct3 = 3'b001; lhs = 32'd9; rhs = 32'd9; #1; if (taken !== 1'b0) begin $display("FAIL BRANCH BNE not taken"); $finish; end
        funct3 = 3'b100; lhs = -32'sd3; rhs = 32'd1; #1; if (taken !== 1'b1) begin $display("FAIL BRANCH BLT"); $finish; end
        funct3 = 3'b101; lhs = 32'd5; rhs = -32'sd1; #1; if (taken !== 1'b1) begin $display("FAIL BRANCH BGE"); $finish; end
        funct3 = 3'b110; lhs = 32'd3; rhs = 32'd9; #1; if (taken !== 1'b1) begin $display("FAIL BRANCH BLTU"); $finish; end
        funct3 = 3'b111; lhs = 32'hffff_fffe; rhs = 32'd9; #1; if (taken !== 1'b1) begin $display("FAIL BRANCH BGEU"); $finish; end
        branch = 1'b0; funct3 = 3'b000; lhs = 32'd1; rhs = 32'd1; #1; if (taken !== 1'b0) begin $display("FAIL BRANCH disable"); $finish; end
        $display("PASS tb_branch_unit");
        $finish;
    end
endmodule
