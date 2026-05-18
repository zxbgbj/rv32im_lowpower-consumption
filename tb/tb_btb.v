`timescale 1ns/1ps
// Testbench: tb_btb.
// Target DUT: btb.
// Coverage: miss behavior, update behavior, tag matching, and target recall.
// Pass rule: hit/target outputs must agree with the most recent valid taken update.
module tb_btb;
    reg clk;
    reg rst;
    reg [31:0] pc;
    wire hit;
    wire [31:0] target;
    reg update_valid;
    reg [31:0] update_pc;
    reg [31:0] update_target;
    reg update_taken;

    btb dut (
        .clk(clk), .rst(rst), .pc(pc), .hit(hit), .target(target),
        .update_valid(update_valid), .update_pc(update_pc), .update_target(update_target), .update_taken(update_taken)
    );

    always #5 clk = ~clk;

    task do_update;
        input [31:0] upd_pc;
        input [31:0] upd_target;
        input        taken;
        begin
            update_valid = 1'b1;
            update_pc = upd_pc;
            update_target = upd_target;
            update_taken = taken;
            @(posedge clk);
            #1;
            update_valid = 1'b0;
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        pc = 0;
        update_valid = 0;
        update_pc = 0;
        update_target = 0;
        update_taken = 0;

        #12;
        rst = 0;
        pc = 32'h40; #1;
        if (hit !== 1'b0) begin $display("FAIL BTB reset"); $finish; end

        do_update(32'h40, 32'h100, 1'b1);
        pc = 32'h40; #1;
        if (!(hit && target == 32'h100)) begin $display("FAIL BTB hit/target"); $finish; end

        pc = 32'h140; #1;
        if (hit !== 1'b0) begin $display("FAIL BTB tag mismatch"); $finish; end

        do_update(32'h80, 32'h180, 1'b0);
        pc = 32'h80; #1;
        if (hit !== 1'b0) begin $display("FAIL BTB not-taken update should not allocate"); $finish; end

        do_update(32'h40, 32'h104, 1'b1);
        pc = 32'h40; #1;
        if (!(hit && target == 32'h104)) begin $display("FAIL BTB rewrite target"); $finish; end

        do_update(32'h00, 32'h200, 1'b1);
        do_update(32'h40, 32'h300, 1'b1);
        pc = 32'h00; #1;
        if (hit !== 1'b0) begin $display("FAIL BTB index collision replacement"); $finish; end
        pc = 32'h40; #1;
        if (!(hit && target == 32'h300)) begin $display("FAIL BTB replacement survivor"); $finish; end

        $display("PASS tb_btb");
        $finish;
    end
endmodule
