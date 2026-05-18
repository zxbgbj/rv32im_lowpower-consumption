`timescale 1ns/1ps
`include "../rtl/memory_profile.vh"
// Testbench: tb_cpu_top_isa.
// Target DUT: cpu_top.
// Coverage: generic ISA-program execution with plusargs for IMEM, DMEM, tohost, and signature ranges.
// Pass rule: tohost or signature-based completion must succeed without unexpected trap or timeout.
module tb_cpu_top_isa;
    reg clk;
    reg rst;
    wire [31:0] imem_addr, dmem_addr, dmem_wdata, fetch_pc, predict_target, redirect_pc, instr32, trap_pc;
    wire [3:0] dmem_we;
    wire fetch_valid, predict_taken, redirect_valid, issue_allow, ex_busy, ex_done, trap_valid, issue_stall, instr_is_compressed, m_busy, m_done;
    wire [1:0] instr_len;

    reg [1023:0] imem_hex;
    reg [1023:0] dmem_hex;
    reg [1023:0] sig_file;
    reg [31:0] tohost_addr;
    reg [31:0] sig_start;
    reg [31:0] sig_end;
    integer max_cycles;
    integer cycle;
    integer idx;
    integer sig_fd;
    integer tohost_word;
    integer sig_start_word;
    integer sig_end_word;
    integer debug_every;
    reg have_dmem;
    reg have_tohost;
    reg have_sig;
    reg debug_isa;
    reg debug_writes;
    reg dump_vcd;
    reg [1023:0] vcd_file;

    cpu_top #(.IMEM_FILE("mem/program.hex")) dut (
        .clk(clk), .rst(rst), .imem_addr(imem_addr), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_we(dmem_we),
        .fetch_valid(fetch_valid), .fetch_pc(fetch_pc), .predict_taken(predict_taken), .predict_target(predict_target), .redirect_valid(redirect_valid), .redirect_pc(redirect_pc),
        .instr32(instr32), .instr_len(instr_len), .instr_is_compressed(instr_is_compressed), .issue_allow(issue_allow), .ex_busy(ex_busy), .ex_done(ex_done),
        .trap_valid(trap_valid), .trap_pc(trap_pc), .issue_stall(issue_stall), .m_busy(m_busy), .m_done(m_done)
    );

    always #5 clk = ~clk;

    task dump_signature;
        integer w;
        begin
            sig_fd = $fopen(sig_file, "w");
            if (sig_fd == 0) begin
                $display("FAIL tb_cpu_top_isa unable to open signature file %0s", sig_file);
                $finish;
            end
            for (w = sig_start_word; w < sig_end_word; w = w + 1) begin
                $fdisplay(sig_fd, "%08x", dut.dmem_bram_u.mem[w]);
            end
            $fclose(sig_fd);
        end
    endtask

    task pass_test;
        begin
            if (dump_vcd) begin
                $dumpflush;
                $dumpoff;
            end
            if (have_sig) begin
                dump_signature();
            end
            $display("PASS tb_cpu_top_isa cycles=%0d", cycle);
            $finish;
        end
    endtask

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        imem_hex = "mem/program.hex";
        dmem_hex = "";
        sig_file = "verification/generated/signature.out";
        tohost_addr = 32'd0;
        sig_start = 32'd0;
        sig_end = 32'd0;
        max_cycles = 5000;
        debug_every = 100000;
        dump_vcd = 1'b0;
        vcd_file = "";
        have_dmem = $value$plusargs("DMEM_HEX=%s", dmem_hex);
        have_tohost = $value$plusargs("TOHOST_ADDR=%h", tohost_addr);
        have_sig = $value$plusargs("SIG_START=%h", sig_start);
        have_sig = have_sig && $value$plusargs("SIG_END=%h", sig_end);
        have_sig = have_sig && $value$plusargs("SIG_FILE=%s", sig_file);
        debug_isa = $test$plusargs("DEBUG_ISA");
        debug_writes = $test$plusargs("DEBUG_WRITES");
        if (!$value$plusargs("DEBUG_EVERY=%d", debug_every)) begin end
        if (!$value$plusargs("IMEM_HEX=%s", imem_hex)) begin end
        if (!$value$plusargs("MAX_CYCLES=%d", max_cycles)) begin end
        dump_vcd = $value$plusargs("VCD_FILE=%s", vcd_file);
        if (dump_vcd) begin
            $dumpfile(vcd_file);
            $dumpvars(0, tb_cpu_top_isa);
            $dumpoff;
        end

        for (idx = 0; idx < `RV32IM_TB_IMEM_INIT_WORDS; idx = idx + 1) begin
            dut.front_end_u.imem_bram_u.mem[idx] = 32'h0000_0013;
        end
        $readmemh(imem_hex, dut.front_end_u.imem_bram_u.mem);
        for (idx = 0; idx < `RV32IM_TB_DMEM_INIT_WORDS; idx = idx + 1) begin
            dut.dmem_bram_u.mem[idx] = 32'd0;
        end
        if (have_dmem) begin
            $readmemh(dmem_hex, dut.dmem_bram_u.mem);
        end

        tohost_word = tohost_addr[31:2];
        sig_start_word = sig_start[31:2];
        sig_end_word = sig_end[31:2];

        #30 rst = 1'b0;
        if (dump_vcd) begin
            $dumpon;
        end
        for (cycle = 0; cycle < max_cycles; cycle = cycle + 1) begin
            @(posedge clk);
            if (debug_isa && debug_writes && dmem_we != 4'b0000) begin
                $display("DBG ISA cyc=%0d pc=%08x dmem_addr=%08x dmem_we=%b dmem_wdata=%08x tohost=%08x",
                         cycle, fetch_pc, dmem_addr, dmem_we, dmem_wdata, dut.dmem_bram_u.mem[tohost_word]);
            end
            if (debug_isa && (debug_every > 0) && ((cycle % debug_every) == 0)) begin
                $display("DBG HEARTBEAT cyc=%0d fetch_pc=%08x if_id_pc=%08x id_ex_pc=%08x ex_mem_pc=%08x instr=%08x tohost=%08x x1=%08x x2=%08x x4=%08x x5=%08x x6=%08x x10=%08x x13=%08x x14=%08x mem_wb_rd=%0d mem_wb_reg_write=%b wb_data=%08x fwdA=%b fwdB=%b dmem_addr=%08x",
                         cycle, fetch_pc, dut.if_id_pc, dut.id_ex_pc, dut.ex_mem_pc, instr32, dut.dmem_bram_u.mem[tohost_word], dut.regfile_u.regs[1],
                         dut.regfile_u.regs[2], dut.regfile_u.regs[4], dut.regfile_u.regs[5], dut.regfile_u.regs[6], dut.regfile_u.regs[10], dut.regfile_u.regs[13], dut.regfile_u.regs[14],
                         dut.mem_wb_rd, dut.mem_wb_reg_write, dut.wb_data, dut.forward_a, dut.forward_b, dmem_addr);
            end
            if (debug_isa && (debug_every > 0) && ((cycle % debug_every) == 0) &&
                (fetch_pc >= 32'h0000_0018) && (fetch_pc <= 32'h0000_0028)) begin
                $display("DBG STARTUP cyc=%0d fetch_pc=%08x id_ex_pc=%08x instr=%08x x5_t0=%08x x6_t1=%08x ex_taken=%b redir=%b redir_pc=%08x dmem_we=%b dmem_addr=%08x",
                         cycle, fetch_pc, dut.id_ex_pc, instr32, dut.regfile_u.regs[5], dut.regfile_u.regs[6],
                         dut.ex_branch_taken, dut.redirect_valid, dut.redirect_pc, dmem_we, dmem_addr);
            end
            if (debug_isa && dut.redirect_valid && (dut.redirect_pc < 32'h0000_0100)) begin
                $display("DBG REDIR LOW cyc=%0d fetch_pc=%08x if_id_pc=%08x id_ex_pc=%08x ex_mem_pc=%08x instr=%08x redir_pc=%08x branch_target=%08x x1=%08x x5=%08x x6=%08x",
                         cycle, fetch_pc, dut.if_id_pc, dut.id_ex_pc, dut.ex_mem_pc, instr32, dut.redirect_pc,
                         dut.ex_branch_target, dut.regfile_u.regs[1], dut.regfile_u.regs[5], dut.regfile_u.regs[6]);
            end
            if (debug_isa && (fetch_pc >= 32'h0000_0400) && (fetch_pc <= 32'h0000_0598)) begin
                $display("DBG ISA cyc=%0d pc=%08x instr=%08x gp=%08x x4=%08x x5=%08x x7=%08x x14=%08x tohost=%08x",
                         cycle, fetch_pc, instr32, dut.regfile_u.regs[3], dut.regfile_u.regs[4],
                         dut.regfile_u.regs[5], dut.regfile_u.regs[7], dut.regfile_u.regs[14],
                         dut.dmem_bram_u.mem[tohost_word]);
            end
            if (debug_isa && (fetch_pc >= 32'h0000_01bc) && (fetch_pc <= 32'h0000_01e0)) begin
                $display("DBG BR cyc=%0d pc=%08x instr=%08x id_ex_pc=%08x rs1=%0d rs2=%0d rs1_val=%08x rs2_val=%08x fwdSelA=%b fwdSelB=%b fwdA=%08x fwdB=%08x exmem_rd=%0d memwb_rd=%0d exmem=%08x wb=%08x branch_cond=%b branch_taken=%b redir=%b redir_pc=%08x",
                         cycle, fetch_pc, instr32, dut.id_ex_pc, dut.id_ex_rs1, dut.id_ex_rs2,
                         dut.id_ex_rs1_val, dut.id_ex_rs2_val, dut.forward_a, dut.forward_b,
                         dut.ex_stage_u.fwd_a, dut.ex_stage_u.fwd_b, dut.ex_mem_rd, dut.mem_wb_rd,
                         dut.ex_mem_alu_result, dut.wb_data, dut.ex_stage_u.branch_cond_taken,
                         dut.ex_branch_taken, dut.redirect_valid, dut.redirect_pc);
            end
            if (trap_valid) begin
                if (dump_vcd) begin
                    $dumpflush;
                    $dumpoff;
                end
                if (have_sig) begin
                    dump_signature();
                end
                $display("FAIL tb_cpu_top_isa unexpected trap at pc=%08x", trap_pc);
                $finish;
            end
            if (have_tohost && dut.dmem_bram_u.mem[tohost_word] !== 32'd0) begin
                if (dut.dmem_bram_u.mem[tohost_word] === 32'd1) begin
                    pass_test();
                end else begin
                    if (dump_vcd) begin
                        $dumpflush;
                        $dumpoff;
                    end
                    if (have_sig) begin
                        dump_signature();
                    end
                    $display("FAIL tb_cpu_top_isa tohost=%08x fail_type=%08x failing_instr=%08x failing_reg=%08x failing_addr=%08x failing_value=%08x expected_value=%08x",
                             dut.dmem_bram_u.mem[tohost_word],
                             dut.dmem_bram_u.mem[32'h00070280 >> 2],
                             dut.dmem_bram_u.mem[32'h00070380 >> 2],
                             dut.dmem_bram_u.mem[32'h00070384 >> 2],
                             dut.dmem_bram_u.mem[32'h00070388 >> 2],
                             dut.dmem_bram_u.mem[32'h00070390 >> 2],
                             dut.dmem_bram_u.mem[32'h00070398 >> 2]);
                    $finish;
                end
            end
        end

        if (dump_vcd) begin
            $dumpflush;
            $dumpoff;
        end
        if (have_sig) begin
            dump_signature();
        end
        $display("FAIL tb_cpu_top_isa timeout after %0d cycles pc=%08x instr=%08x gp=%08x x4=%08x x5=%08x x6=%08x x7=%08x x14=%08x tohost=%08x",
                 max_cycles, fetch_pc, instr32, dut.regfile_u.regs[3], dut.regfile_u.regs[4],
                 dut.regfile_u.regs[5], dut.regfile_u.regs[6], dut.regfile_u.regs[7], dut.regfile_u.regs[14],
                 dut.dmem_bram_u.mem[tohost_word]);
        $finish;
    end
endmodule
