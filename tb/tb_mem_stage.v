`timescale 1ns/1ps
// Testbench: tb_mem_stage.
// Target DUT: mem_stage.
// Coverage: store byte-enable generation and load sign/zero extension for B, H, and W transfers.
// Pass rule: write masks, aligned write data, and formatted load data must match each transfer type.
module tb_mem_stage;
    reg [31:0] alu_result;
    reg [31:0] store_data;
    reg mem_read;
    reg mem_write;
    reg [1:0] mem_size;
    reg load_unsigned;
    reg [31:0] dmem_rdata;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [3:0] dmem_we;
    wire [31:0] load_data;

    mem_stage dut (
        .alu_result(alu_result), .store_data(store_data), .mem_read(mem_read), .mem_write(mem_write), .mem_size(mem_size), .load_unsigned(load_unsigned),
        .dmem_rdata(dmem_rdata), .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_we(dmem_we), .load_data(load_data)
    );

    initial begin
        alu_result = 32'h0000_0080; store_data = 32'h1234_abcd; mem_read = 1'b0; mem_write = 1'b1; mem_size = 2'd2; load_unsigned = 1'b0; dmem_rdata = 32'h89ab_cdef; #1;
        if (dmem_addr !== 32'h80 || dmem_wdata !== 32'h1234_abcd || dmem_we !== 4'b1111) begin $display("FAIL MEM SW"); $finish; end

        alu_result = 32'h0000_0082; store_data = 32'h0000_beef; mem_size = 2'd1; #1;
        if (dmem_wdata !== 32'hbeef_0000 || dmem_we !== 4'b1100) begin $display("FAIL MEM SH upper"); $finish; end

        alu_result = 32'h0000_0081; store_data = 32'h0000_00ee; mem_size = 2'd0; #1;
        if (dmem_wdata !== 32'h0000_ee00 || dmem_we !== 4'b0010) begin $display("FAIL MEM SB offset1"); $finish; end

        mem_write = 1'b0; mem_read = 1'b1; alu_result = 32'h0000_0080; dmem_rdata = 32'h8001_abcd; mem_size = 2'd2; load_unsigned = 1'b0; #1;
        if (load_data !== 32'h8001_abcd) begin $display("FAIL MEM LW"); $finish; end

        mem_size = 2'd1; load_unsigned = 1'b0; #1;
        if (load_data !== 32'hffff_abcd) begin $display("FAIL MEM LH sign"); $finish; end

        mem_size = 2'd1; load_unsigned = 1'b1; #1;
        if (load_data !== 32'h0000_abcd) begin $display("FAIL MEM LHU"); $finish; end

        alu_result = 32'h0000_0083; dmem_rdata = 32'h80ff_7f01; mem_size = 2'd0; load_unsigned = 1'b0; #1;
        if (load_data !== 32'hffff_ff80) begin $display("FAIL MEM LB sign"); $finish; end

        load_unsigned = 1'b1; #1;
        if (load_data !== 32'h0000_0080) begin $display("FAIL MEM LBU"); $finish; end

        mem_read = 1'b0; #1;
        if (dmem_we !== 4'b0000) begin $display("FAIL MEM idle"); $finish; end
        $display("PASS tb_mem_stage");
        $finish;
    end
endmodule
