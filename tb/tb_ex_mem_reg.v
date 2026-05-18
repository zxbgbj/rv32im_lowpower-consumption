`timescale 1ns/1ps
// Testbench: tb_ex_mem_reg.
// Target DUT: ex_mem_reg.
// Coverage: reset and enabled capture of EX-to-MEM pipeline state.
// Pass rule: outputs must reset cleanly and only update when enable is asserted.
module tb_ex_mem_reg;
    reg clk;
    reg rst;
    reg enable;
    reg [31:0] pc_in, alu_result_in, store_data_in, branch_target_in;
    reg [4:0] rd_in;
    reg mem_read_in, mem_write_in, reg_write_in, mem_to_reg_in, load_unsigned_in, branch_taken_in;
    reg [1:0] mem_size_in;
    wire [31:0] pc_out, alu_result_out, store_data_out, branch_target_out;
    wire [4:0] rd_out;
    wire mem_read_out, mem_write_out, reg_write_out, mem_to_reg_out, load_unsigned_out, branch_taken_out;
    wire [1:0] mem_size_out;

    ex_mem_reg dut (
        .clk(clk), .rst(rst), .enable(enable), .pc_in(pc_in), .alu_result_in(alu_result_in), .store_data_in(store_data_in), .rd_in(rd_in),
        .mem_read_in(mem_read_in), .mem_write_in(mem_write_in), .reg_write_in(reg_write_in), .mem_to_reg_in(mem_to_reg_in),
        .mem_size_in(mem_size_in), .load_unsigned_in(load_unsigned_in), .branch_taken_in(branch_taken_in), .branch_target_in(branch_target_in),
        .pc_out(pc_out), .alu_result_out(alu_result_out), .store_data_out(store_data_out), .rd_out(rd_out), .mem_read_out(mem_read_out),
        .mem_write_out(mem_write_out), .reg_write_out(reg_write_out), .mem_to_reg_out(mem_to_reg_out), .mem_size_out(mem_size_out),
        .load_unsigned_out(load_unsigned_out), .branch_taken_out(branch_taken_out), .branch_target_out(branch_target_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; enable = 1;
        pc_in = 32'd10; alu_result_in = 32'd20; store_data_in = 32'd30; rd_in = 5'd5;
        mem_read_in = 1; mem_write_in = 0; reg_write_in = 1; mem_to_reg_in = 1; mem_size_in = 2'd1; load_unsigned_in = 1; branch_taken_in = 1; branch_target_in = 32'd64;
        #12; rst = 0; #10;
        if (alu_result_out !== 32'd20 || branch_target_out !== 32'd64 || rd_out !== 5'd5 || mem_size_out !== 2'd1 || load_unsigned_out !== 1'b1) begin
            $display("FAIL EXMEM latch"); $finish;
        end
        enable = 0; alu_result_in = 32'd99; #10;
        if (alu_result_out !== 32'd20) begin $display("FAIL EXMEM enable hold"); $finish; end
        $display("PASS tb_ex_mem_reg");
        $finish;
    end
endmodule

