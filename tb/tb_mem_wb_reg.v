`timescale 1ns/1ps
// Testbench: tb_mem_wb_reg.
// Target DUT: mem_wb_reg.
// Coverage: reset and enabled capture of MEM-to-WB state.
// Pass rule: write-back candidates must reset cleanly and only update when enable is asserted.
module tb_mem_wb_reg;
    reg clk;
    reg rst;
    reg enable;
    reg [31:0] alu_result_in, mem_rdata_in;
    reg [4:0] rd_in;
    reg reg_write_in, mem_to_reg_in;
    wire [31:0] alu_result_out, mem_rdata_out;
    wire [4:0] rd_out;
    wire reg_write_out, mem_to_reg_out;

    mem_wb_reg dut (
        .clk(clk), .rst(rst), .enable(enable), .alu_result_in(alu_result_in), .mem_rdata_in(mem_rdata_in), .rd_in(rd_in),
        .reg_write_in(reg_write_in), .mem_to_reg_in(mem_to_reg_in), .alu_result_out(alu_result_out), .mem_rdata_out(mem_rdata_out),
        .rd_out(rd_out), .reg_write_out(reg_write_out), .mem_to_reg_out(mem_to_reg_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; enable = 1; alu_result_in = 32'd100; mem_rdata_in = 32'd200; rd_in = 5'd9; reg_write_in = 1; mem_to_reg_in = 1;
        #12; rst = 0; #10;
        if (alu_result_out !== 32'd100 || mem_rdata_out !== 32'd200 || rd_out !== 5'd9 || reg_write_out !== 1'b1) begin
            $display("FAIL MEMWB latch"); $finish;
        end
        enable = 0; alu_result_in = 32'd11; #10;
        if (alu_result_out !== 32'd100) begin $display("FAIL MEMWB enable hold"); $finish; end
        $display("PASS tb_mem_wb_reg");
        $finish;
    end
endmodule

