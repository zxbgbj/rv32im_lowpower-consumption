`timescale 1ns/1ps
// Testbench: tb_cpu_top_m_extension.
// Target DUT: cpu_top.
// Coverage: top-level execution of RV32M instructions through the pipeline and multicycle hold logic.
// Pass rule: multiply/divide/remainder program results must match the expected architectural values.
module tb_cpu_top_m_extension;
    reg clk;
    reg rst;
    wire [31:0] imem_addr, dmem_addr, dmem_wdata, fetch_pc, predict_target, redirect_pc, instr32, trap_pc;
    wire [3:0] dmem_we;
    wire fetch_valid, predict_taken, redirect_valid, issue_allow, ex_busy, ex_done, trap_valid, issue_stall, instr_is_compressed, m_busy, m_done;
    wire [1:0] instr_len;

    cpu_top #(.IMEM_FILE("mem/program_m.hex")) dut (
        .clk(clk), .rst(rst), .imem_addr(imem_addr), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_we(dmem_we),
        .fetch_valid(fetch_valid), .fetch_pc(fetch_pc), .predict_taken(predict_taken), .predict_target(predict_target), .redirect_valid(redirect_valid), .redirect_pc(redirect_pc),
        .instr32(instr32), .instr_len(instr_len), .instr_is_compressed(instr_is_compressed), .issue_allow(issue_allow), .ex_busy(ex_busy), .ex_done(ex_done),
        .trap_valid(trap_valid), .trap_pc(trap_pc), .issue_stall(issue_stall), .m_busy(m_busy), .m_done(m_done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1;
        #30 rst = 0;
        repeat (1200) @(posedge clk);
        if (trap_valid) begin $display("FAIL M TOP trap"); $finish; end
        if (dut.regfile_u.regs[3]  !== 32'd42) begin $display("FAIL M TOP x3 MUL"); $finish; end
        if (dut.regfile_u.regs[4]  !== 32'd0) begin $display("FAIL M TOP x4 MULH"); $finish; end
        if (dut.regfile_u.regs[6]  !== 32'hffff_ffff) begin $display("FAIL M TOP x6 MULHSU"); $finish; end
        if (dut.regfile_u.regs[7]  !== 32'd0) begin $display("FAIL M TOP x7 MULHU"); $finish; end
        if (dut.regfile_u.regs[10] !== 32'd14) begin $display("FAIL M TOP x10 DIV"); $finish; end
        if (dut.regfile_u.regs[11] !== 32'd14) begin $display("FAIL M TOP x11 DIVU"); $finish; end
        if (dut.regfile_u.regs[12] !== 32'd2) begin $display("FAIL M TOP x12 REM"); $finish; end
        if (dut.regfile_u.regs[13] !== 32'd2) begin $display("FAIL M TOP x13 REMU"); $finish; end
        if (dut.regfile_u.regs[15] !== 32'hffff_ffff) begin $display("FAIL M TOP x15 DIV0"); $finish; end
        if (dut.regfile_u.regs[16] !== 32'd100) begin $display("FAIL M TOP x16 REM0"); $finish; end
        if (dut.regfile_u.regs[19] !== 32'h8000_0000) begin $display("FAIL M TOP x19 DIV overflow"); $finish; end
        if (dut.regfile_u.regs[20] !== 32'd0) begin $display("FAIL M TOP x20 REM overflow"); $finish; end
        $display("PASS tb_cpu_top_m_extension");
        $finish;
    end
endmodule
