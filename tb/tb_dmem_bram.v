`timescale 1ns/1ps
// Testbench: tb_dmem_bram.
// Target DUT: dmem_bram.
// Coverage: write enables, synchronous read behavior, and low-power en gating.
// Pass rule: writes must honor byte masks and read data must hold when en is low.
module tb_dmem_bram;
    reg clk;
    reg en;
    reg [31:0] addr;
    reg [31:0] wdata;
    reg [3:0] we;
    wire [31:0] rdata;

    dmem_bram #(.DEPTH_WORDS(8)) dut (
        .clk(clk), .en(en), .addr(addr), .wdata(wdata), .we(we), .rdata(rdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        en = 1'b1;
        addr = 32'd0;
        wdata = 32'h11223344;
        we = 4'b1111;
        @(posedge clk);
        we = 4'b0000;
        @(posedge clk);
        #1;
        if (rdata !== 32'h11223344) begin $display("FAIL DMEM write/read"); $finish; end

        addr = 32'd4;
        wdata = 32'h55667788;
        we = 4'b0011;
        @(posedge clk);
        we = 4'b0000;
        @(posedge clk);
        #1;
        if (rdata[15:0] !== 16'h7788) begin $display("FAIL DMEM byte enable"); $finish; end

        en = 1'b0;
        addr = 32'd0;
        @(posedge clk);
        #1;
        if (rdata[15:0] !== 16'h7788) begin $display("FAIL DMEM hold when disabled"); $finish; end
        $display("PASS tb_dmem_bram");
        $finish;
    end
endmodule
