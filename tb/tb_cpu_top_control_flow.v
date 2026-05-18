`timescale 1ns/1ps
// Testbench: tb_cpu_top_control_flow.
// Target DUT: cpu_top.
// Coverage: branch, jump, redirect, and flush behavior through the full pipeline.
// Pass rule: the control-flow program must update architectural state exactly as expected.
module tb_cpu_top_control_flow;
    reg clk;
    reg rst;
    wire [31:0] imem_addr, dmem_addr, dmem_wdata;
    wire [3:0] dmem_we;
    wire fetch_valid, redirect_valid, ex_busy, ex_done, trap_valid, issue_stall;
    wire [31:0] redirect_pc, trap_pc;

    cpu_top #(.IMEM_FILE("mem/program_control.hex")) dut (
        .clk(clk), .rst(rst), .imem_addr(imem_addr), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_we(dmem_we),
        .fetch_valid(fetch_valid), .redirect_valid(redirect_valid), .redirect_pc(redirect_pc), .ex_busy(ex_busy), .ex_done(ex_done),
        .trap_valid(trap_valid), .trap_pc(trap_pc), .issue_stall(issue_stall)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1;
        #30; rst = 0; #500;
        if (dut.regfile_u.regs[3] !== 32'd0) begin $display("FAIL CTRL x3 not skipped"); $finish; end
        if (dut.regfile_u.regs[5] !== 32'd24) begin $display("FAIL CTRL x5 jalr ra"); $finish; end
        if (dut.regfile_u.regs[6] !== 32'd0) begin $display("FAIL CTRL x6 should skip"); $finish; end
        if (dut.regfile_u.regs[7] !== 32'd0) begin $display("FAIL CTRL x7 should skip"); $finish; end
        if (dut.regfile_u.regs[8] !== 32'd36) begin $display("FAIL CTRL x8 jal ra"); $finish; end
        if (dut.regfile_u.regs[10] !== 32'd10) begin $display("FAIL CTRL x10"); $finish; end
        if (dut.regfile_u.regs[11] !== 32'd11) begin $display("FAIL CTRL x11"); $finish; end
        $display("PASS tb_cpu_top_control_flow");
        $finish;
    end
endmodule
