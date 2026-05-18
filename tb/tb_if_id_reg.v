`timescale 1ns/1ps
// Testbench: tb_if_id_reg.
// Target DUT: if_id_reg.
// Coverage: reset, flush, stall hold behavior, and fetch metadata capture.
// Pass rule: instruction and prediction fields must hold or clear according to stall/flush control.
module tb_if_id_reg;
    reg clk;
    reg rst;
    reg stall;
    reg flush;
    reg [31:0] pc_in;
    reg [31:0] instr_in;
    reg [1:0] instr_len_in;
    reg instr_is_compressed_in;
    reg predict_taken_in;
    reg [31:0] predict_target_in;
    reg [7:0] predict_history_in;
    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [1:0] instr_len_out;
    wire instr_is_compressed_out;
    wire predict_taken_out;
    wire [31:0] predict_target_out;
    wire [7:0] predict_history_out;

    if_id_reg dut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .pc_in(pc_in),
        .instr_in(instr_in),
        .instr_len_in(instr_len_in),
        .instr_is_compressed_in(instr_is_compressed_in),
        .predict_taken_in(predict_taken_in),
        .predict_target_in(predict_target_in),
        .predict_history_in(predict_history_in),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .instr_len_out(instr_len_out),
        .instr_is_compressed_out(instr_is_compressed_out),
        .predict_taken_out(predict_taken_out),
        .predict_target_out(predict_target_out),
        .predict_history_out(predict_history_out)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; stall = 0; flush = 0;
        pc_in = 0; instr_in = 0; instr_len_in = 2'd2; instr_is_compressed_in = 0; predict_taken_in = 0; predict_target_in = 0; predict_history_in = 0;
        #12;
        rst = 0;
        pc_in = 32'd8; instr_in = 32'h12345678; instr_len_in = 2'd2; predict_taken_in = 1'b1; predict_target_in = 32'h40; predict_history_in = 8'h3c;
        #10;
        if (pc_out !== 32'd8 || instr_out !== 32'h12345678 || instr_len_out !== 2'd2 || !predict_taken_out || predict_target_out !== 32'h40 || predict_history_out !== 8'h3c) begin
            $display("FAIL IFID latch"); $finish;
        end
        stall = 1; pc_in = 32'd12; instr_in = 32'h87654321; #10;
        if (pc_out !== 32'd8 || instr_out !== 32'h12345678) begin $display("FAIL IFID stall"); $finish; end
        stall = 0; flush = 1; #10; flush = 0;
        if (instr_out !== 32'h00000013 || instr_len_out !== 2'd2 || predict_taken_out !== 1'b0) begin $display("FAIL IFID flush"); $finish; end
        $display("PASS tb_if_id_reg");
        $finish;
    end
endmodule

