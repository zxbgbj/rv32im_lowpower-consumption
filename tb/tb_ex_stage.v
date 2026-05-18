`timescale 1ns/1ps
// Testbench: tb_ex_stage.
// Target DUT: ex_stage.
// Coverage: ALU result generation, branch resolution, and EX-stage result selection.
// Pass rule: EX outputs must match the supplied operands and control bundle.
module tb_ex_stage;
    reg [31:0] pc;
    reg [31:0] rs1_val;
    reg [31:0] rs2_val;
    reg [31:0] imm;
    reg [3:0] alu_ctrl;
    reg alu_src;
    reg branch;
    reg jump;
    reg jalr;
    reg [2:0] funct3;
    reg [1:0] forward_a_sel;
    reg [1:0] forward_b_sel;
    reg [31:0] ex_mem_fwd_data;
    reg [31:0] mem_wb_fwd_data;
    wire [31:0] alu_result;
    wire [31:0] store_data;
    wire branch_taken;
    wire [31:0] branch_target;

    ex_stage dut (
        .pc(pc), .rs1_val(rs1_val), .rs2_val(rs2_val), .imm(imm), .alu_ctrl(alu_ctrl), .alu_src(alu_src),
        .branch(branch), .jump(jump), .jalr(jalr), .funct3(funct3), .forward_a_sel(forward_a_sel), .forward_b_sel(forward_b_sel),
        .ex_mem_fwd_data(ex_mem_fwd_data), .mem_wb_fwd_data(mem_wb_fwd_data), .alu_result(alu_result), .store_data(store_data),
        .branch_taken(branch_taken), .branch_target(branch_target)
    );

    initial begin
        pc = 32'd16; rs1_val = 32'd7; rs2_val = 32'd5; imm = 32'd4; alu_ctrl = 4'd0; alu_src = 0; branch = 0; jump = 0; jalr = 0; funct3 = 0;
        forward_a_sel = 0; forward_b_sel = 0; ex_mem_fwd_data = 0; mem_wb_fwd_data = 0; #1;
        if (alu_result !== 12) begin $display("FAIL EX add"); $finish; end
        forward_a_sel = 2'b10; ex_mem_fwd_data = 32'd20; #1; if (alu_result !== 25) begin $display("FAIL EX forward A"); $finish; end
        forward_a_sel = 0; forward_b_sel = 2'b01; mem_wb_fwd_data = 32'd9; #1; if (store_data !== 9 || alu_result !== 16) begin $display("FAIL EX forward B/store"); $finish; end
        forward_b_sel = 0; alu_ctrl = 4'd10; alu_src = 1; imm = 32'h1000; #1; if (alu_result !== 32'h1000) begin $display("FAIL EX LUI"); $finish; end
        alu_ctrl = 4'd11; pc = 32'd64; imm = 32'h20; #1; if (alu_result !== 32'd96) begin $display("FAIL EX AUIPC"); $finish; end
        jump = 1; jalr = 0; pc = 32'd100; imm = 32'd8; #1; if (!(branch_taken && alu_result == 32'd104 && branch_target == 32'd108)) begin $display("FAIL EX JAL"); $finish; end
        jump = 1; jalr = 1; rs1_val = 32'd40; imm = 32'd12; #1; if (branch_target !== 32'd52) begin $display("FAIL EX JALR"); $finish; end
        jump = 0; jalr = 0; branch = 1; funct3 = 3'b000; rs1_val = 32'd3; rs2_val = 32'd3; pc = 32'd20; imm = 32'd16; #1;
        if (!(branch_taken && branch_target == 32'd36)) begin $display("FAIL EX branch"); $finish; end
        $display("PASS tb_ex_stage");
        $finish;
    end
endmodule
