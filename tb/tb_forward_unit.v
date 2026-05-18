`timescale 1ns/1ps
// Testbench: tb_forward_unit.
// Target DUT: forward_unit.
// Coverage: EX and MEM forwarding select generation, including no-forward cases.
// Pass rule: ForwardA and ForwardB must match the expected dependency source.
module tb_forward_unit;
    reg [4:0] id_ex_rs1;
    reg [4:0] id_ex_rs2;
    reg [4:0] ex_mem_rd;
    reg ex_mem_reg_write;
    reg [4:0] mem_wb_rd;
    reg mem_wb_reg_write;
    wire [1:0] forward_a;
    wire [1:0] forward_b;

    forward_unit dut (
        .id_ex_rs1(id_ex_rs1), .id_ex_rs2(id_ex_rs2), .ex_mem_rd(ex_mem_rd), .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd(mem_wb_rd), .mem_wb_reg_write(mem_wb_reg_write), .forward_a(forward_a), .forward_b(forward_b)
    );

    initial begin
        id_ex_rs1 = 5'd3; id_ex_rs2 = 5'd4;
        ex_mem_rd = 5'd3; ex_mem_reg_write = 1'b1;
        mem_wb_rd = 5'd4; mem_wb_reg_write = 1'b1;
        #1;
        if (forward_a !== 2'b10 || forward_b !== 2'b01) begin $display("FAIL FORWARD mixed priority"); $finish; end

        ex_mem_rd = 5'd3; ex_mem_reg_write = 1'b1;
        mem_wb_rd = 5'd3; mem_wb_reg_write = 1'b1;
        id_ex_rs1 = 5'd3; id_ex_rs2 = 5'd7;
        #1;
        if (forward_a !== 2'b10) begin $display("FAIL FORWARD exmem priority over memwb"); $finish; end

        ex_mem_rd = 5'd0; ex_mem_reg_write = 1'b1;
        mem_wb_rd = 5'd4; mem_wb_reg_write = 1'b1;
        id_ex_rs1 = 5'd1; id_ex_rs2 = 5'd4;
        #1;
        if (forward_a !== 2'b00 || forward_b !== 2'b01) begin $display("FAIL FORWARD zero register ignore"); $finish; end

        ex_mem_rd = 5'd9; ex_mem_reg_write = 0;
        mem_wb_rd = 5'd0; mem_wb_reg_write = 0;
        id_ex_rs1 = 5'd9; id_ex_rs2 = 5'd9;
        #1;
        if (forward_a !== 2'b00 || forward_b !== 2'b00) begin $display("FAIL FORWARD disabled writes"); $finish; end

        ex_mem_rd = 5'd8; ex_mem_reg_write = 1;
        mem_wb_rd = 5'd9; mem_wb_reg_write = 1;
        id_ex_rs1 = 5'd1; id_ex_rs2 = 5'd8;
        #1;
        if (forward_a !== 2'b00 || forward_b !== 2'b10) begin $display("FAIL FORWARD rs2 from exmem"); $finish; end

        $display("PASS tb_forward_unit");
        $finish;
    end
endmodule
