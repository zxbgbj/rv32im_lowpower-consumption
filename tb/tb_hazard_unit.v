`timescale 1ns/1ps
// Testbench: tb_hazard_unit.
// Target DUT: hazard_unit.
// Coverage: load-use stall, control flush, and no-hazard pass-through cases.
// Pass rule: stall and flush outputs must assert only for the expected hazard patterns.
module tb_hazard_unit;
    reg id_ex_mem_read;
    reg [4:0] id_ex_rd;
    reg ex_mem_mem_read;
    reg [4:0] ex_mem_rd;
    reg [4:0] if_id_rs1;
    reg [4:0] if_id_rs2;
    reg if_id_uses_rs1;
    reg if_id_uses_rs2;
    wire stall;

    hazard_unit dut (
        .id_ex_mem_read(id_ex_mem_read), .id_ex_rd(id_ex_rd),
        .ex_mem_mem_read(ex_mem_mem_read), .ex_mem_rd(ex_mem_rd),
        .if_id_rs1(if_id_rs1), .if_id_rs2(if_id_rs2),
        .if_id_uses_rs1(if_id_uses_rs1), .if_id_uses_rs2(if_id_uses_rs2), .stall(stall)
    );

    initial begin
        id_ex_mem_read = 1'b1; id_ex_rd = 5'd8;
        ex_mem_mem_read = 1'b0; ex_mem_rd = 5'd0;
        if_id_rs1 = 5'd8; if_id_rs2 = 5'd0;
        if_id_uses_rs1 = 1'b1; if_id_uses_rs2 = 1'b0;
        #1;
        if (stall !== 1'b1) begin $display("FAIL HAZARD rs1 trigger"); $finish; end

        if_id_rs1 = 5'd0; if_id_rs2 = 5'd8;
        if_id_uses_rs1 = 1'b0; if_id_uses_rs2 = 1'b1;
        #1;
        if (stall !== 1'b1) begin $display("FAIL HAZARD rs2 trigger"); $finish; end

        id_ex_rd = 5'd0;
        #1;
        if (stall !== 1'b0) begin $display("FAIL HAZARD zero rd ignore"); $finish; end

        id_ex_rd = 5'd7; id_ex_mem_read = 1'b1;
        if_id_rs1 = 5'd7; if_id_uses_rs1 = 1'b0;
        if_id_rs2 = 5'd9; if_id_uses_rs2 = 1'b0;
        #1;
        if (stall !== 1'b0) begin $display("FAIL HAZARD unused source should not stall"); $finish; end

        if_id_rs1 = 5'd7; if_id_uses_rs1 = 1'b1;
        #1;
        if (stall !== 1'b1) begin $display("FAIL HAZARD resume stall"); $finish; end

        id_ex_mem_read = 1'b0;
        #1;
        if (stall !== 1'b0) begin $display("FAIL HAZARD clear when no load"); $finish; end

        ex_mem_mem_read = 1'b1; ex_mem_rd = 5'd11;
        if_id_rs1 = 5'd11; if_id_uses_rs1 = 1'b1;
        #1;
        if (stall !== 1'b1) begin $display("FAIL HAZARD ex_mem rs1 trigger"); $finish; end

        if_id_rs1 = 5'd0; if_id_rs2 = 5'd11;
        if_id_uses_rs1 = 1'b0; if_id_uses_rs2 = 1'b1;
        #1;
        if (stall !== 1'b1) begin $display("FAIL HAZARD ex_mem rs2 trigger"); $finish; end

        ex_mem_rd = 5'd0;
        #1;
        if (stall !== 1'b0) begin $display("FAIL HAZARD ex_mem zero rd ignore"); $finish; end

        $display("PASS tb_hazard_unit");
        $finish;
    end
endmodule
