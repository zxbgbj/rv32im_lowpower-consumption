`timescale 1ns/1ps
// Testbench: tb_wb_stage.
// Target DUT: wb_stage.
// Coverage: ALU result versus load-data write-back selection.
// Pass rule: wb_data must follow mem_to_reg selection exactly.
module tb_wb_stage;
    reg [31:0] alu_result;
    reg [31:0] mem_rdata;
    reg mem_to_reg;
    wire [31:0] wb_data;

    wb_stage dut (.alu_result(alu_result), .mem_rdata(mem_rdata), .mem_to_reg(mem_to_reg), .wb_data(wb_data));

    initial begin
        alu_result = 32'd12; mem_rdata = 32'd99; mem_to_reg = 0; #1; if (wb_data !== 32'd12) begin $display("FAIL WB alu"); $finish; end
        mem_to_reg = 1; #1; if (wb_data !== 32'd99) begin $display("FAIL WB mem"); $finish; end
        $display("PASS tb_wb_stage");
        $finish;
    end
endmodule
