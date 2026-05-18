`timescale 1ns/1ps
// Testbench: tb_csr_file.
// Target DUT: csr_file.
// Coverage: CSR read/write, trap entry bookkeeping, and machine-cycle counter behavior.
// Pass rule: CSR outputs, mepc, mcause, cycle aliases, and mcycle increment/write behavior must match the directed scenarios.
module tb_csr_file;
    reg clk;
    reg rst;
    reg [11:0] read_addr;
    wire [31:0] read_data;
    reg write_en;
    reg [11:0] write_addr;
    reg [31:0] write_data;
    reg trap_enter;
    reg [31:0] trap_pc;
    reg [31:0] trap_cause;
    wire [31:0] mtvec, mepc, mcause, mstatus;

    csr_file dut (
        .clk(clk), .rst(rst), .read_addr(read_addr), .read_data(read_data),
        .write_en(write_en), .write_addr(write_addr), .write_data(write_data),
        .trap_enter(trap_enter), .trap_pc(trap_pc), .trap_cause(trap_cause),
        .mtvec(mtvec), .mepc(mepc), .mcause(mcause), .mstatus(mstatus)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; read_addr = 12'h300; write_en = 0; write_addr = 12'd0; write_data = 32'd0; trap_enter = 0; trap_pc = 0; trap_cause = 0;
        repeat (2) @(posedge clk);
        rst = 0;

        read_addr = 12'hb00; #1; if (read_data !== 32'd0) begin $display("FAIL CSR reset mcycle"); $finish; end
        read_addr = 12'hc00; #1; if (read_data !== 32'd0) begin $display("FAIL CSR reset cycle alias"); $finish; end

        write_en = 1; write_addr = 12'hb00; write_data = 32'h1234_5678; @(posedge clk);
        write_en = 0;
        read_addr = 12'hb00; #1; if (read_data !== 32'h1234_5678) begin $display("FAIL CSR write mcycle low"); $finish; end
        read_addr = 12'hc00; #1; if (read_data !== 32'h1234_5678) begin $display("FAIL CSR read cycle low alias"); $finish; end

        @(posedge clk);
        read_addr = 12'hb00; #1; if (read_data !== 32'h1234_5679) begin $display("FAIL CSR increment mcycle low"); $finish; end

        write_en = 1; write_addr = 12'hb80; write_data = 32'h9abc_def0; @(posedge clk);
        write_en = 0;
        read_addr = 12'hb80; #1; if (read_data !== 32'h9abc_def0) begin $display("FAIL CSR write mcycle high"); $finish; end
        read_addr = 12'hc80; #1; if (read_data !== 32'h9abc_def0) begin $display("FAIL CSR read cycle high alias"); $finish; end

        write_en = 1; write_addr = 12'hb80; write_data = 32'h0000_0000; @(posedge clk);
        write_addr = 12'hb00; write_data = 32'hffff_fffe; @(posedge clk);
        write_en = 0;
        read_addr = 12'hb80; #1; if (read_data !== 32'h0000_0000) begin $display("FAIL CSR preset mcycle high"); $finish; end
        read_addr = 12'hb00; #1; if (read_data !== 32'hffff_fffe) begin $display("FAIL CSR preset mcycle low"); $finish; end

        @(posedge clk);
        @(posedge clk);
        read_addr = 12'hb80; #1; if (read_data !== 32'h0000_0001) begin $display("FAIL CSR mcycle carry high"); $finish; end
        read_addr = 12'hb00; #1; if (read_data !== 32'h0000_0000) begin $display("FAIL CSR mcycle carry low"); $finish; end

        write_en = 1; write_addr = 12'h305; write_data = 32'h0000_0080; #10;
        write_addr = 12'h300; write_data = 32'h0000_1800; #10;
        write_en = 0;
        if (mtvec !== 32'h0000_0080) begin $display("FAIL CSR mtvec"); $finish; end
        if (mstatus !== 32'h0000_1800) begin $display("FAIL CSR mstatus"); $finish; end

        trap_enter = 1; trap_pc = 32'h0000_0040; trap_cause = 32'd11; #10; trap_enter = 0;
        if (mepc !== 32'h0000_0040) begin $display("FAIL CSR mepc"); $finish; end
        if (mcause !== 32'd11) begin $display("FAIL CSR mcause"); $finish; end

        read_addr = 12'h305; #1; if (read_data !== 32'h0000_0080) begin $display("FAIL CSR read mtvec"); $finish; end
        read_addr = 12'h341; #1; if (read_data !== 32'h0000_0040) begin $display("FAIL CSR read mepc"); $finish; end
        read_addr = 12'h342; #1; if (read_data !== 32'd11) begin $display("FAIL CSR read mcause"); $finish; end
        read_addr = 12'h300; #1; if (read_data !== 32'h0000_1800) begin $display("FAIL CSR read mstatus"); $finish; end
        $display("PASS tb_csr_file");
        $finish;
    end
endmodule
