`timescale 1ns/1ps
// Testbench: tb_cpu_top_mmode.
// Target DUT: cpu_top.
// Coverage: minimal machine-mode trap entry, CSR state update, and mret return behavior.
// Pass rule: trap handling and return path must preserve the expected control flow and state.
module tb_cpu_top_mmode;
    reg clk;
    reg rst;
    wire [31:0] imem_addr, dmem_addr, dmem_wdata, fetch_pc, predict_target, redirect_pc, instr32, trap_pc;
    wire [3:0] dmem_we;
    wire fetch_valid, predict_taken, redirect_valid, issue_allow, ex_busy, ex_done, trap_valid, issue_stall, instr_is_compressed, m_busy, m_done;
    wire [1:0] instr_len;

    cpu_top #(.IMEM_FILE("mem/program_mmode.hex")) dut (
        .clk(clk), .rst(rst), .imem_addr(imem_addr), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_we(dmem_we),
        .fetch_valid(fetch_valid), .fetch_pc(fetch_pc), .predict_taken(predict_taken), .predict_target(predict_target), .redirect_valid(redirect_valid), .redirect_pc(redirect_pc),
        .instr32(instr32), .instr_len(instr_len), .instr_is_compressed(instr_is_compressed), .issue_allow(issue_allow), .ex_busy(ex_busy), .ex_done(ex_done),
        .trap_valid(trap_valid), .trap_pc(trap_pc), .issue_stall(issue_stall), .m_busy(m_busy), .m_done(m_done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1;
        #30 rst = 0;
        repeat (500) begin
            @(posedge clk);
            if (dut.fetch_pc <= 32'd160 || dut.redirect_valid || dut.trap_valid) begin
                $display("DBG MMODE pc=%0d instr=%08x trap=%b trap_pc=%0d redir=%b redir_pc=%0d x10=%0d x11=%0d x12=%0d x13=%0d x14=%0d mepc=%0d mcause=%0d",
                         dut.fetch_pc,
                         dut.instr32,
                         dut.trap_valid,
                         dut.trap_pc,
                         dut.redirect_valid,
                         dut.redirect_pc,
                         dut.regfile_u.regs[10],
                         dut.regfile_u.regs[11],
                         dut.regfile_u.regs[12],
                         dut.regfile_u.regs[13],
                         dut.regfile_u.regs[14],
                         dut.csr_file_u.mepc,
                         dut.csr_file_u.mcause);
            end
        end
        if (dut.regfile_u.regs[10] !== 32'd2) begin
            $display("FAIL MMODE x10 trap counter x10=%0d x11=%0d x12=%0d x13=%0d x14=%0d mtvec=%0d mepc=%0d mcause=%0d",
                     dut.regfile_u.regs[10],
                     dut.regfile_u.regs[11],
                     dut.regfile_u.regs[12],
                     dut.regfile_u.regs[13],
                     dut.regfile_u.regs[14],
                     dut.csr_file_u.mtvec,
                     dut.csr_file_u.mepc,
                     dut.csr_file_u.mcause);
            $finish;
        end
        if (dut.regfile_u.regs[11] !== 32'd1) begin $display("FAIL MMODE x11 after ecall x11=%0d", dut.regfile_u.regs[11]); $finish; end
        if (dut.regfile_u.regs[12] !== 32'd7) begin $display("FAIL MMODE x12 after ebreak x12=%0d", dut.regfile_u.regs[12]); $finish; end
        if (dut.regfile_u.regs[13] !== 32'h0000_0018) begin $display("FAIL MMODE x13 mepc read x13=%0d", dut.regfile_u.regs[13]); $finish; end
        if (dut.regfile_u.regs[14] !== 32'd3) begin $display("FAIL MMODE x14 mcause read x14=%0d", dut.regfile_u.regs[14]); $finish; end
        if (dut.csr_file_u.mtvec !== 32'h0000_0080) begin $display("FAIL MMODE mtvec mtvec=%0d", dut.csr_file_u.mtvec); $finish; end
        if (dut.csr_file_u.mepc !== 32'h0000_0018) begin $display("FAIL MMODE mepc mepc=%0d", dut.csr_file_u.mepc); $finish; end
        $display("PASS tb_cpu_top_mmode");
        $finish;
    end
endmodule
