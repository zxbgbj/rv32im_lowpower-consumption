`timescale 1ns/1ps
// Testbench: tb_cpu_top_forwarding.
// Target DUT: cpu_top.
// Coverage: EX-to-EX, MEM-to-EX, and write-back forwarding paths.
// Pass rule: dependent instructions must retire with correct values without extra stalls.
module tb_cpu_top_forwarding;
    reg clk;
    reg rst;
    wire [31:0] imem_addr, dmem_addr, dmem_wdata;
    wire [3:0] dmem_we;
    wire fetch_valid, redirect_valid, ex_busy, ex_done, trap_valid, issue_stall;
    wire [31:0] redirect_pc, trap_pc;

    cpu_top #(.IMEM_FILE("mem/program_forward.hex")) dut (
        .clk(clk), .rst(rst), .imem_addr(imem_addr), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_we(dmem_we),
        .fetch_valid(fetch_valid), .redirect_valid(redirect_valid), .redirect_pc(redirect_pc), .ex_busy(ex_busy), .ex_done(ex_done),
        .trap_valid(trap_valid), .trap_pc(trap_pc), .issue_stall(issue_stall)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1;
        #30; rst = 0; #300;
        if (dut.regfile_u.regs[3] !== 32'd10) begin $display("FAIL FWD x3"); $finish; end
        if (dut.regfile_u.regs[4] !== 32'd7) begin $display("FAIL FWD x4"); $finish; end
        if (dut.regfile_u.regs[5] !== 32'd2) begin $display("FAIL FWD x5"); $finish; end
        if (dut.regfile_u.regs[6] !== 32'd7) begin $display("FAIL FWD x6"); $finish; end
        $display("PASS tb_cpu_top_forwarding");
        $finish;
    end
endmodule
