`timescale 1ns/1ps
// Testbench: tb_id_ex_reg.
// Target DUT: id_ex_reg.
// Coverage: reset, flush, and enabled transfer of the full decode bundle.
// Pass rule: control/data fields must clear on reset/flush and capture only when enable is high.
module tb_id_ex_reg;
    reg clk;
    reg rst;
    reg enable;
    reg flush;
    reg [31:0] pc_in, rs1_val_in, rs2_val_in, imm_in;
    reg [4:0] rs1_in, rs2_in, rd_in;
    reg [2:0] funct3_in;
    reg [3:0] alu_ctrl_in;
    reg alu_src_in, mem_read_in, mem_write_in, reg_write_in, mem_to_reg_in, branch_in, jump_in, jalr_in;
    reg load_unsigned_in;
    reg [1:0] mem_size_in;
    reg m_valid_in;
    reg [2:0] m_op_in;
    reg predict_taken_in;
    reg [31:0] predict_target_in;
    reg [7:0] predict_history_in;
    reg csr_valid_in;
    reg [2:0] csr_cmd_in;
    reg [11:0] csr_addr_in;
    reg csr_use_imm_in;
    reg [31:0] csr_rdata_in;
    reg sys_ecall_in, sys_ebreak_in, sys_mret_in, sys_illegal_in, fence_i_in;
    wire [31:0] pc_out, rs1_val_out, rs2_val_out, imm_out;
    wire [4:0] rs1_out, rs2_out, rd_out;
    wire [2:0] funct3_out;
    wire [3:0] alu_ctrl_out;
    wire alu_src_out, mem_read_out, mem_write_out, reg_write_out, mem_to_reg_out, branch_out, jump_out, jalr_out;
    wire load_unsigned_out, m_valid_out, predict_taken_out, csr_valid_out, csr_use_imm_out, sys_ecall_out, sys_ebreak_out, sys_mret_out, sys_illegal_out, fence_i_out;
    wire [1:0] mem_size_out;
    wire [2:0] m_op_out, csr_cmd_out;
    wire [11:0] csr_addr_out;
    wire [31:0] predict_target_out, csr_rdata_out;
    wire [7:0] predict_history_out;

    id_ex_reg dut (
        .clk(clk), .rst(rst), .enable(enable), .flush(flush),
        .pc_in(pc_in), .rs1_val_in(rs1_val_in), .rs2_val_in(rs2_val_in), .imm_in(imm_in),
        .rs1_in(rs1_in), .rs2_in(rs2_in), .rd_in(rd_in), .funct3_in(funct3_in), .alu_ctrl_in(alu_ctrl_in), .alu_src_in(alu_src_in),
        .mem_read_in(mem_read_in), .mem_write_in(mem_write_in), .reg_write_in(reg_write_in), .mem_to_reg_in(mem_to_reg_in),
        .branch_in(branch_in), .jump_in(jump_in), .jalr_in(jalr_in), .load_unsigned_in(load_unsigned_in), .mem_size_in(mem_size_in),
        .m_valid_in(m_valid_in), .m_op_in(m_op_in), .predict_taken_in(predict_taken_in), .predict_target_in(predict_target_in), .predict_history_in(predict_history_in),
        .csr_valid_in(csr_valid_in), .csr_cmd_in(csr_cmd_in), .csr_addr_in(csr_addr_in), .csr_use_imm_in(csr_use_imm_in), .csr_rdata_in(csr_rdata_in),
        .sys_ecall_in(sys_ecall_in), .sys_ebreak_in(sys_ebreak_in), .sys_mret_in(sys_mret_in), .sys_illegal_in(sys_illegal_in), .fence_i_in(fence_i_in),
        .pc_out(pc_out), .rs1_val_out(rs1_val_out), .rs2_val_out(rs2_val_out), .imm_out(imm_out), .rs1_out(rs1_out), .rs2_out(rs2_out), .rd_out(rd_out),
        .funct3_out(funct3_out), .alu_ctrl_out(alu_ctrl_out), .alu_src_out(alu_src_out), .mem_read_out(mem_read_out), .mem_write_out(mem_write_out),
        .reg_write_out(reg_write_out), .mem_to_reg_out(mem_to_reg_out), .branch_out(branch_out), .jump_out(jump_out), .jalr_out(jalr_out),
        .load_unsigned_out(load_unsigned_out), .mem_size_out(mem_size_out), .m_valid_out(m_valid_out), .m_op_out(m_op_out),
        .predict_taken_out(predict_taken_out), .predict_target_out(predict_target_out), .predict_history_out(predict_history_out), .csr_valid_out(csr_valid_out), .csr_cmd_out(csr_cmd_out),
        .csr_addr_out(csr_addr_out), .csr_use_imm_out(csr_use_imm_out), .csr_rdata_out(csr_rdata_out),
        .sys_ecall_out(sys_ecall_out), .sys_ebreak_out(sys_ebreak_out), .sys_mret_out(sys_mret_out), .sys_illegal_out(sys_illegal_out), .fence_i_out(fence_i_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; enable = 1; flush = 0;
        pc_in = 32'd20; rs1_val_in = 32'd1; rs2_val_in = 32'd2; imm_in = 32'd3;
        rs1_in = 5'd1; rs2_in = 5'd2; rd_in = 5'd3; funct3_in = 3'b010; alu_ctrl_in = 4'd5;
        alu_src_in = 1; mem_read_in = 1; mem_write_in = 0; reg_write_in = 1; mem_to_reg_in = 1; branch_in = 0; jump_in = 0; jalr_in = 0;
        load_unsigned_in = 1; mem_size_in = 2'd1; m_valid_in = 1; m_op_in = 3'd4; predict_taken_in = 1; predict_target_in = 32'h80; predict_history_in = 8'h5a;
        csr_valid_in = 1; csr_cmd_in = 3'b010; csr_addr_in = 12'h341; csr_use_imm_in = 0; csr_rdata_in = 32'h1234;
        sys_ecall_in = 1; sys_ebreak_in = 0; sys_mret_in = 0; sys_illegal_in = 0; fence_i_in = 1;
        #12; rst = 0; #10;
        if (pc_out !== 32'd20 || rd_out !== 5'd3 || mem_read_out !== 1'b1 || alu_ctrl_out !== 4'd5 || csr_valid_out !== 1'b1 || m_valid_out !== 1'b1 || fence_i_out !== 1'b1 || predict_history_out !== 8'h5a) begin
            $display("FAIL IDEX latch"); $finish;
        end
        enable = 0; pc_in = 32'd44; #10;
        if (pc_out !== 32'd20) begin $display("FAIL IDEX enable hold"); $finish; end
        enable = 1; flush = 1; #10; flush = 0;
        if (reg_write_out !== 0 || mem_read_out !== 0 || mem_write_out !== 0 ||
            branch_out !== 0 || jump_out !== 0 || jalr_out !== 0 ||
            csr_valid_out !== 0 || m_valid_out !== 0 || fence_i_out !== 0 ||
            sys_ecall_out !== 0 || sys_ebreak_out !== 0 || sys_mret_out !== 0 ||
            sys_illegal_out !== 0 || predict_taken_out !== 0) begin
            $display("FAIL IDEX flush"); $finish;
        end
        $display("PASS tb_id_ex_reg");
        $finish;
    end
endmodule

