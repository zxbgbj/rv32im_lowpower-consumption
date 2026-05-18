`timescale 1ns/1ps
// Testbench: tb_cpu_top_load_hazard.
// Target DUT: cpu_top.
// Coverage: load-use stall generation and recovery.
// Pass rule: the dependent consumer instruction must see the correct loaded value after a single hold.
module tb_cpu_top_load_hazard;
    reg clk;
    reg rst;
    wire [31:0] imem_addr, dmem_addr, dmem_wdata;
    wire [3:0] dmem_we;
    wire fetch_valid, redirect_valid, ex_busy, ex_done, trap_valid, issue_stall;
    wire [31:0] redirect_pc, trap_pc;

    cpu_top #(.IMEM_FILE("mem/program_load_hazard.hex")) dut (
        .clk(clk), .rst(rst), .imem_addr(imem_addr), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_we(dmem_we),
        .fetch_valid(fetch_valid), .redirect_valid(redirect_valid), .redirect_pc(redirect_pc), .ex_busy(ex_busy), .ex_done(ex_done),
        .trap_valid(trap_valid), .trap_pc(trap_pc), .issue_stall(issue_stall)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1;
        #30; rst = 0; #400;
        if (dut.dmem_bram_u.mem[0] !== 32'd21) begin $display("FAIL LOAD dmem0"); $finish; end
        if (dut.regfile_u.regs[3] !== 32'd21) begin $display("FAIL LOAD x3"); $finish; end
        if (dut.regfile_u.regs[4] !== 32'd42) begin $display("FAIL LOAD x4"); $finish; end
        if (dut.regfile_u.regs[6] !== 32'd2) begin $display("FAIL LOAD branch result"); $finish; end
        $display("PASS tb_cpu_top_load_hazard");
        $finish;
    end
endmodule
