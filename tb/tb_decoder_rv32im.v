`timescale 1ns/1ps
// Testbench: tb_decoder_rv32im.
// Target DUT: decoder_rv32im.
// Coverage: RV32I, RV32M, and minimal system/CSR decode outputs.
// Pass rule: control outputs must match opcode, funct3, funct7, and system instruction expectations.
module tb_decoder_rv32im;
    reg  [31:0] instr;
    wire [4:0] rs1, rs2, rd;
    wire [2:0] funct3;
    wire [3:0] alu_ctrl;
    wire alu_src, mem_read, mem_write, reg_write, mem_to_reg, branch, jump, jalr, uses_rs1, uses_rs2, illegal, load_unsigned, m_valid, csr_valid, csr_use_imm, sys_ecall, sys_ebreak, sys_mret, fence_i;
    wire [1:0] mem_size;
    wire [2:0] m_op, csr_cmd;
    wire [11:0] csr_addr;

    decoder_rv32im dut (
        .instr(instr), .rs1(rs1), .rs2(rs2), .rd(rd), .funct3(funct3), .alu_ctrl(alu_ctrl), .alu_src(alu_src),
        .mem_read(mem_read), .mem_write(mem_write), .reg_write(reg_write), .mem_to_reg(mem_to_reg), .branch(branch), .jump(jump), .jalr(jalr),
        .uses_rs1(uses_rs1), .uses_rs2(uses_rs2), .illegal(illegal), .load_unsigned(load_unsigned), .mem_size(mem_size), .m_valid(m_valid), .m_op(m_op),
        .csr_valid(csr_valid), .csr_cmd(csr_cmd), .csr_addr(csr_addr), .csr_use_imm(csr_use_imm), .sys_ecall(sys_ecall), .sys_ebreak(sys_ebreak), .sys_mret(sys_mret), .fence_i(fence_i)
    );

    initial begin
        instr = {7'b0000000,5'd2,5'd1,3'b000,5'd3,7'b0110011}; #1; if (!(reg_write && !illegal && alu_ctrl == 4'd0)) begin $display("FAIL DEC ADD"); $finish; end
        instr = {7'b0100000,5'd2,5'd1,3'b000,5'd3,7'b0110011}; #1; if (!(reg_write && alu_ctrl == 4'd1)) begin $display("FAIL DEC SUB"); $finish; end
        instr = {7'b0000000,5'd2,5'd1,3'b001,5'd3,7'b0110011}; #1; if (alu_ctrl != 4'd7) begin $display("FAIL DEC SLL"); $finish; end
        instr = {7'b0000000,5'd2,5'd1,3'b010,5'd3,7'b0110011}; #1; if (alu_ctrl != 4'd5) begin $display("FAIL DEC SLT"); $finish; end
        instr = {7'b0000000,5'd2,5'd1,3'b011,5'd3,7'b0110011}; #1; if (alu_ctrl != 4'd6) begin $display("FAIL DEC SLTU"); $finish; end
        instr = {7'b0000000,5'd2,5'd1,3'b100,5'd3,7'b0110011}; #1; if (alu_ctrl != 4'd4) begin $display("FAIL DEC XOR"); $finish; end
        instr = {7'b0000000,5'd2,5'd1,3'b101,5'd3,7'b0110011}; #1; if (alu_ctrl != 4'd8) begin $display("FAIL DEC SRL"); $finish; end
        instr = {7'b0100000,5'd2,5'd1,3'b101,5'd3,7'b0110011}; #1; if (alu_ctrl != 4'd9) begin $display("FAIL DEC SRA"); $finish; end
        instr = {7'b0000000,5'd2,5'd1,3'b110,5'd3,7'b0110011}; #1; if (alu_ctrl != 4'd3) begin $display("FAIL DEC OR"); $finish; end
        instr = {7'b0000000,5'd2,5'd1,3'b111,5'd3,7'b0110011}; #1; if (alu_ctrl != 4'd2) begin $display("FAIL DEC AND"); $finish; end

        instr = {12'd5,5'd1,3'b000,5'd3,7'b0010011}; #1; if (!(reg_write && alu_src && alu_ctrl == 4'd0)) begin $display("FAIL DEC ADDI"); $finish; end
        instr = {12'd1,5'd1,3'b010,5'd3,7'b0010011}; #1; if (alu_ctrl != 4'd5) begin $display("FAIL DEC SLTI"); $finish; end
        instr = {12'd1,5'd1,3'b011,5'd3,7'b0010011}; #1; if (alu_ctrl != 4'd6) begin $display("FAIL DEC SLTIU"); $finish; end
        instr = {12'd1,5'd1,3'b100,5'd3,7'b0010011}; #1; if (alu_ctrl != 4'd4) begin $display("FAIL DEC XORI"); $finish; end
        instr = {12'd1,5'd1,3'b110,5'd3,7'b0010011}; #1; if (alu_ctrl != 4'd3) begin $display("FAIL DEC ORI"); $finish; end
        instr = {12'd1,5'd1,3'b111,5'd3,7'b0010011}; #1; if (alu_ctrl != 4'd2) begin $display("FAIL DEC ANDI"); $finish; end
        instr = {7'b0000000,5'd3,5'd1,3'b001,5'd3,7'b0010011}; #1; if (alu_ctrl != 4'd7) begin $display("FAIL DEC SLLI"); $finish; end
        instr = {7'b0000000,5'd3,5'd1,3'b101,5'd3,7'b0010011}; #1; if (alu_ctrl != 4'd8) begin $display("FAIL DEC SRLI"); $finish; end
        instr = {7'b0100000,5'd3,5'd1,3'b101,5'd3,7'b0010011}; #1; if (alu_ctrl != 4'd9) begin $display("FAIL DEC SRAI"); $finish; end

        instr = {12'd0,5'd1,3'b000,5'd3,7'b0000011}; #1; if (!(mem_read && mem_to_reg && mem_size == 2'd0 && !load_unsigned)) begin $display("FAIL DEC LB"); $finish; end
        instr = {12'd0,5'd1,3'b001,5'd3,7'b0000011}; #1; if (!(mem_read && mem_size == 2'd1 && !load_unsigned)) begin $display("FAIL DEC LH"); $finish; end
        instr = {12'd0,5'd1,3'b010,5'd3,7'b0000011}; #1; if (!(mem_read && mem_size == 2'd2 && !load_unsigned)) begin $display("FAIL DEC LW"); $finish; end
        instr = {12'd0,5'd1,3'b100,5'd3,7'b0000011}; #1; if (!(mem_read && mem_size == 2'd0 && load_unsigned)) begin $display("FAIL DEC LBU"); $finish; end
        instr = {12'd0,5'd1,3'b101,5'd3,7'b0000011}; #1; if (!(mem_read && mem_size == 2'd1 && load_unsigned)) begin $display("FAIL DEC LHU"); $finish; end

        instr = {7'd0,5'd2,5'd1,3'b000,5'd0,7'b0100011}; #1; if (!(mem_write && mem_size == 2'd0)) begin $display("FAIL DEC SB"); $finish; end
        instr = {7'd0,5'd2,5'd1,3'b001,5'd0,7'b0100011}; #1; if (!(mem_write && mem_size == 2'd1)) begin $display("FAIL DEC SH"); $finish; end
        instr = {7'd0,5'd2,5'd1,3'b010,5'd0,7'b0100011}; #1; if (!(mem_write && mem_size == 2'd2)) begin $display("FAIL DEC SW"); $finish; end

        instr = {1'b0,6'd0,5'd2,5'd1,3'b000,4'd0,1'b0,7'b1100011}; #1; if (!(branch && !illegal)) begin $display("FAIL DEC BEQ"); $finish; end
        instr[14:12] = 3'b001; #1; if (!branch) begin $display("FAIL DEC BNE"); $finish; end
        instr[14:12] = 3'b100; #1; if (!branch) begin $display("FAIL DEC BLT"); $finish; end
        instr[14:12] = 3'b101; #1; if (!branch) begin $display("FAIL DEC BGE"); $finish; end
        instr[14:12] = 3'b110; #1; if (!branch) begin $display("FAIL DEC BLTU"); $finish; end
        instr[14:12] = 3'b111; #1; if (!branch) begin $display("FAIL DEC BGEU"); $finish; end

        instr = {20'd0,5'd1,7'b1101111}; #1; if (!(jump && reg_write && !jalr)) begin $display("FAIL DEC JAL"); $finish; end
        instr = {12'd0,5'd1,3'b000,5'd2,7'b1100111}; #1; if (!(jump && jalr && reg_write && alu_src)) begin $display("FAIL DEC JALR"); $finish; end
        instr = {20'h12345,5'd1,7'b0110111}; #1; if (!(reg_write && alu_ctrl == 4'd10)) begin $display("FAIL DEC LUI"); $finish; end
        instr = {20'h00001,5'd1,7'b0010111}; #1; if (!(reg_write && alu_ctrl == 4'd11)) begin $display("FAIL DEC AUIPC"); $finish; end

        instr = 32'h0000000f; #1; if (illegal || fence_i) begin $display("FAIL DEC FENCE"); $finish; end
        instr = 32'h0000100f; #1; if (illegal || !fence_i) begin $display("FAIL DEC FENCEI"); $finish; end

        instr = {7'b0000001,5'd2,5'd1,3'b000,5'd3,7'b0110011}; #1; if (!(m_valid && m_op == 3'd0)) begin $display("FAIL DEC MUL"); $finish; end
        instr[14:12] = 3'b001; #1; if (!(m_valid && m_op == 3'd1)) begin $display("FAIL DEC MULH"); $finish; end
        instr[14:12] = 3'b010; #1; if (!(m_valid && m_op == 3'd2)) begin $display("FAIL DEC MULHSU"); $finish; end
        instr[14:12] = 3'b011; #1; if (!(m_valid && m_op == 3'd3)) begin $display("FAIL DEC MULHU"); $finish; end
        instr[14:12] = 3'b100; #1; if (!(m_valid && m_op == 3'd4)) begin $display("FAIL DEC DIV"); $finish; end
        instr[14:12] = 3'b101; #1; if (!(m_valid && m_op == 3'd5)) begin $display("FAIL DEC DIVU"); $finish; end
        instr[14:12] = 3'b110; #1; if (!(m_valid && m_op == 3'd6)) begin $display("FAIL DEC REM"); $finish; end
        instr[14:12] = 3'b111; #1; if (!(m_valid && m_op == 3'd7)) begin $display("FAIL DEC REMU"); $finish; end

        instr = {12'h305,5'd1,3'b001,5'd2,7'b1110011}; #1; if (!(csr_valid && csr_cmd == 3'b001 && !csr_use_imm)) begin $display("FAIL DEC CSRRW"); $finish; end
        instr = {12'h305,5'd1,3'b010,5'd2,7'b1110011}; #1; if (!(csr_valid && csr_cmd == 3'b010)) begin $display("FAIL DEC CSRRS"); $finish; end
        instr = {12'h305,5'd1,3'b011,5'd2,7'b1110011}; #1; if (!(csr_valid && csr_cmd == 3'b011)) begin $display("FAIL DEC CSRRC"); $finish; end
        instr = {12'h305,5'd1,3'b101,5'd2,7'b1110011}; #1; if (!(csr_valid && csr_cmd == 3'b101 && csr_use_imm)) begin $display("FAIL DEC CSRRWI"); $finish; end
        instr = {12'h305,5'd1,3'b110,5'd2,7'b1110011}; #1; if (!(csr_valid && csr_cmd == 3'b110 && csr_use_imm)) begin $display("FAIL DEC CSRRSI"); $finish; end
        instr = {12'h305,5'd1,3'b111,5'd2,7'b1110011}; #1; if (!(csr_valid && csr_cmd == 3'b111 && csr_use_imm)) begin $display("FAIL DEC CSRRCI"); $finish; end

        instr = 32'h00000073; #1; if (!sys_ecall) begin $display("FAIL DEC ECALL"); $finish; end
        instr = 32'h00100073; #1; if (!sys_ebreak) begin $display("FAIL DEC EBREAK"); $finish; end
        instr = 32'h30200073; #1; if (!sys_mret) begin $display("FAIL DEC MRET"); $finish; end

        instr = 32'hffff_ffff; #1; if (!illegal) begin $display("FAIL DEC ILLEGAL"); $finish; end
        $display("PASS tb_decoder_rv32im");
        $finish;
    end
endmodule
