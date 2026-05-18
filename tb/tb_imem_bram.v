`timescale 1ns/1ps
// Testbench: tb_imem_bram.
// Target DUT: imem_bram.
// Coverage: synchronous instruction read behavior and low-power en gating.
// Pass rule: fetch data must update only when en is high and must hold when en is low.
module tb_imem_bram;
    reg clk;
    reg en;
    reg [31:0] addr;
    reg en_b;
    reg [3:0] we_b;
    reg [31:0] addr_b;
    reg [31:0] wdata_b;
    wire [31:0] rdata;
    wire [31:0] rdata_b;

    imem_bram #(.MEM_FILE("mem/imem_tb.hex"), .DEPTH_WORDS(8)) dut (
        .clk(clk),
        .en(en),
        .addr(addr),
        .rdata(rdata),
        .en_b(en_b),
        .we_b(we_b),
        .addr_b(addr_b),
        .wdata_b(wdata_b),
        .rdata_b(rdata_b)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        en = 1'b1;
        en_b = 1'b1;
        we_b = 4'b0000;
        addr = 32'd0;
        addr_b = 32'd4;
        wdata_b = 32'd0;
        @(posedge clk);
        #1;
        if (rdata !== 32'h12345678) begin $display("FAIL IMEM word0 port A"); $finish; end
        if (rdata_b !== 32'h89abcdef) begin $display("FAIL IMEM word1 port B"); $finish; end

        en = 1'b0;
        en_b = 1'b0;
        addr = 32'd4;
        addr_b = 32'd0;
        @(posedge clk);
        #1;
        if (rdata !== 32'h12345678 || rdata_b !== 32'h89abcdef) begin $display("FAIL IMEM hold when disabled"); $finish; end

        en = 1'b1;
        en_b = 1'b1;
        @(posedge clk);
        #1;
        if (rdata !== 32'h89abcdef) begin $display("FAIL IMEM word1 port A"); $finish; end
        if (rdata_b !== 32'h12345678) begin $display("FAIL IMEM word0 port B"); $finish; end

        en = 1'b0;
        en_b = 1'b1;
        we_b = 4'b1111;
        addr_b = 32'd0;
        wdata_b = 32'hdeadbeef;
        @(posedge clk);
        #1;

        en = 1'b1;
        en_b = 1'b1;
        we_b = 4'b0000;
        addr = 32'd0;
        addr_b = 32'd0;
        @(posedge clk);
        #1;
        if (rdata !== 32'hdeadbeef) begin $display("FAIL IMEM write-through port B"); $finish; end
        $display("PASS tb_imem_bram");
        $finish;
    end
endmodule
