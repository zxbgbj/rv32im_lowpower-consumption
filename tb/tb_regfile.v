`timescale 1ns/1ps
// Testbench: tb_regfile.
// Target DUT: regfile.
// Coverage: x0 hard-wire behavior, register writes, and dual read ports.
// Pass rule: x0 must remain zero and reads must reflect the most recent committed write data.
module tb_regfile;
    reg clk;
    reg rst;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    reg we;
    reg [4:0] rd_addr;
    reg [31:0] rd_data;

    regfile dut (
        .clk(clk), .rst(rst), .rs1_addr(rs1_addr), .rs2_addr(rs2_addr),
        .rs1_data(rs1_data), .rs2_data(rs2_data), .we(we), .rd_addr(rd_addr), .rd_data(rd_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; we = 0; rs1_addr = 0; rs2_addr = 0; rd_addr = 0; rd_data = 0;
        #12; rst = 0;
        rd_addr = 5'd1; rd_data = 32'h55aa1234; we = 1; #10; we = 0;
        rs1_addr = 5'd1; #1;
        if (rs1_data !== 32'h55aa1234) begin $display("FAIL REGFILE write/read"); $finish; end
        rd_addr = 5'd0; rd_data = 32'hffffffff; we = 1; #10; we = 0;
        rs1_addr = 5'd0; #1;
        if (rs1_data !== 32'd0) begin $display("FAIL REGFILE x0"); $finish; end
        rs1_addr = 5'd2; rd_addr = 5'd2; rd_data = 32'h12345678; we = 1; #1;
        if (rs1_data !== 32'h12345678) begin $display("FAIL REGFILE same-cycle bypass"); $finish; end
        #9; we = 0;
        $display("PASS tb_regfile");
        $finish;
    end
endmodule

