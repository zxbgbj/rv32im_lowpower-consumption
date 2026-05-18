`timescale 1ns/1ps
// Testbench: tb_cpu_top.
// Target DUT: cpu_top.
// Coverage: basic top-level smoke behavior for the low-power RV32IM core.
// Pass rule: the bundled sample program must complete without unexpected trap or timeout.
module tb_cpu_top;
    reg clk;
    reg rst;
    wire [31:0] imem_addr, dmem_addr, dmem_wdata, fetch_pc, predict_target, redirect_pc, instr32, trap_pc;
    wire [3:0] dmem_we;
    wire fetch_valid, predict_taken, redirect_valid, issue_allow, ex_busy, ex_done, trap_valid, issue_stall, instr_is_compressed, m_busy, m_done;
    wire [1:0] instr_len;

    cpu_top #(.IMEM_FILE("mem/program.hex")) dut (
        .clk(clk), .rst(rst), .imem_addr(imem_addr), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_we(dmem_we),
        .fetch_valid(fetch_valid), .fetch_pc(fetch_pc), .predict_taken(predict_taken), .predict_target(predict_target), .redirect_valid(redirect_valid), .redirect_pc(redirect_pc),
        .instr32(instr32), .instr_len(instr_len), .instr_is_compressed(instr_is_compressed), .issue_allow(issue_allow), .ex_busy(ex_busy), .ex_done(ex_done),
        .trap_valid(trap_valid), .trap_pc(trap_pc), .issue_stall(issue_stall), .m_busy(m_busy), .m_done(m_done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        #30;
        rst = 1'b0;
        repeat (120) @(posedge clk);
        if (!fetch_valid) begin $display("FAIL: frontend did not become valid"); $finish; end
        if (trap_valid) begin $display("FAIL: unexpected trap at pc=%08x", trap_pc); $finish; end
        if (dut.regfile_u.regs[3] !== 32'd14) begin $display("FAIL: x3 expected 14"); $finish; end
        if (dut.regfile_u.regs[4] !== 32'd14) begin $display("FAIL: x4 expected 14"); $finish; end
        $display("PASS tb_cpu_top");
        $finish;
    end
endmodule

