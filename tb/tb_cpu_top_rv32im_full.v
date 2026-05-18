`timescale 1ns/1ps
// Testbench: tb_cpu_top_rv32im_full.
// Target DUT: cpu_top.
// Coverage: broad RV32I and RV32M instruction regression using a bundled full-program image.
// Pass rule: the regression program must complete with the expected register and memory side effects.
module tb_cpu_top_rv32im_full;
    reg clk;
    reg rst;
    integer cycle;
    wire [31:0] imem_addr, dmem_addr, dmem_wdata, fetch_pc, predict_target, redirect_pc, instr32, trap_pc;
    wire [3:0] dmem_we;
    wire fetch_valid, predict_taken, redirect_valid, issue_allow, ex_busy, ex_done, trap_valid, issue_stall, instr_is_compressed, m_busy, m_done;
    wire [1:0] instr_len;

    cpu_top #(.IMEM_FILE("mem/program_rv32im_full.hex")) dut (
        .clk(clk), .rst(rst), .imem_addr(imem_addr), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_we(dmem_we),
        .fetch_valid(fetch_valid), .fetch_pc(fetch_pc), .predict_taken(predict_taken), .predict_target(predict_target), .redirect_valid(redirect_valid), .redirect_pc(redirect_pc),
        .instr32(instr32), .instr_len(instr_len), .instr_is_compressed(instr_is_compressed), .issue_allow(issue_allow), .ex_busy(ex_busy), .ex_done(ex_done),
        .trap_valid(trap_valid), .trap_pc(trap_pc), .issue_stall(issue_stall), .m_busy(m_busy), .m_done(m_done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1;
        #30 rst = 0;
        for (cycle = 0; cycle < 500; cycle = cycle + 1) begin
            @(posedge clk);
            if ((cycle >= 34 && cycle <= 46) ||
                (dut.if_id_pc >= 32'd120 && dut.if_id_pc <= 32'd168) ||
                (dut.id_ex_pc >= 32'd120 && dut.id_ex_pc <= 32'd168) ||
                (dut.ex_mem_pc >= 32'd120 && dut.ex_mem_pc <= 32'd168) ||
                (dut.regfile_u.regs[28] != 32'd0)) begin
                $display("DBG FULL cyc=%0d req_pc=%0d fe_pc=%0d fe_valid=%b fe_instr=%08x if_id_pc=%0d if_id_instr=%08x id_ex_pc=%0d id_ex_branch=%b funct3=%0d ex_taken=%b ex_target=%0d redir=%b redir_pc=%0d x28=%0d",
                         cycle,
                         dut.front_end_u.pc_req,
                         dut.fe_fetch_pc,
                         dut.fe_fetch_valid,
                         dut.fe_instr32,
                         dut.if_id_pc,
                         dut.if_id_instr,
                         dut.id_ex_pc,
                         dut.id_ex_branch,
                         dut.id_ex_funct3,
                         dut.ex_branch_taken,
                         dut.ex_branch_target,
                         dut.redirect_valid,
                         dut.redirect_pc,
                         dut.regfile_u.regs[28]);
            end
        end
        if (trap_valid) begin $display("FAIL FULL unexpected trap %08x", trap_pc); $finish; end
        if (dut.regfile_u.regs[1]  !== 32'h1234_5000) begin $display("FAIL FULL x1"); $finish; end
        if (dut.regfile_u.regs[2]  !== 32'd4) begin $display("FAIL FULL x2"); $finish; end
        if (dut.regfile_u.regs[5]  !== 32'd1) begin $display("FAIL FULL x5"); $finish; end
        if (dut.regfile_u.regs[12] !== 32'hffff_fffe) begin $display("FAIL FULL x12"); $finish; end
        if (dut.regfile_u.regs[13] !== 32'd26) begin $display("FAIL FULL x13"); $finish; end
        if (dut.regfile_u.regs[20] !== 32'hffff_ffff) begin $display("FAIL FULL x20"); $finish; end
        if (dut.regfile_u.regs[23] !== 32'd26) begin $display("FAIL FULL x23"); $finish; end
        if (dut.regfile_u.regs[24] !== 32'd31) begin $display("FAIL FULL x24"); $finish; end
        if (dut.regfile_u.regs[25] !== 32'd31) begin $display("FAIL FULL x25"); $finish; end
        if (dut.regfile_u.regs[26] !== 32'd5) begin $display("FAIL FULL x26"); $finish; end
        if (dut.regfile_u.regs[27] !== 32'd5) begin $display("FAIL FULL x27"); $finish; end
        if (dut.regfile_u.regs[28] !== 32'd0) begin
            $display("FAIL FULL x28 branches x28=%0d x23=%0d x13=%0d x3=%0d x4=%0d",
                     dut.regfile_u.regs[28],
                     dut.regfile_u.regs[23],
                     dut.regfile_u.regs[13],
                     dut.regfile_u.regs[3],
                     dut.regfile_u.regs[4]);
            $finish;
        end
        if (dut.regfile_u.regs[29] !== 32'd123) begin $display("FAIL FULL x29 jal/jalr"); $finish; end
        if (dut.regfile_u.regs[30] !== 32'd172) begin $display("FAIL FULL x30 jal ra"); $finish; end
        if (dut.regfile_u.regs[31] !== 32'd184) begin $display("FAIL FULL x31 jalr ra"); $finish; end
        if (dut.dmem_bram_u.mem[0] !== 32'd26) begin $display("FAIL FULL mem0"); $finish; end
        if (dut.dmem_bram_u.mem[1] !== 32'h0005_001f) begin $display("FAIL FULL mem1"); $finish; end
        $display("PASS tb_cpu_top_rv32im_full");
        $finish;
    end
endmodule
