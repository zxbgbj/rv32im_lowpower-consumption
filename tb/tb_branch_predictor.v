`timescale 1ns/1ps
// Testbench: tb_branch_predictor.
// Target DUT: branch_predictor.
// Coverage: cold prediction, update training, saturation behavior, and reset-safe output behavior.
// Pass rule: the taken bit must follow the expected 2-bit counter state transitions.
module tb_branch_predictor;
    reg clk;
    reg rst;
    reg [31:0] pc;
    wire predict_taken;
    wire [7:0] query_history;
    reg update_valid;
    reg [31:0] update_pc;
    reg [7:0] update_history;
    reg update_taken;

    branch_predictor dut (
        .clk(clk), .rst(rst), .pc(pc), .predict_taken(predict_taken), .query_history(query_history),
        .update_valid(update_valid), .update_pc(update_pc), .update_history(update_history), .update_taken(update_taken)
    );

    always #5 clk = ~clk;

    task do_update;
        input [31:0] upd_pc;
        input [7:0]  hist;
        input        taken;
        begin
            update_valid = 1'b1;
            update_pc = upd_pc;
            update_history = hist;
            update_taken = taken;
            @(posedge clk);
            #1;
            update_valid = 1'b0;
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        pc = 32'h20;
        update_valid = 0;
        update_pc = 0;
        update_history = 0;
        update_taken = 0;

        #1;
        if (predict_taken !== 1'b0) begin $display("FAIL BHT output under reset"); $finish; end

        #11;
        rst = 0;
        #1;
        if (predict_taken !== 1'b1) begin $display("FAIL BHT weakly-taken reset bias"); $finish; end

        do_update(32'h20, 8'h00, 1'b0);
        pc = 32'h20; #1;
        if (predict_taken !== 1'b0) begin $display("FAIL gshare weakly-not-taken transition"); $finish; end

        do_update(32'h20, 8'h00, 1'b0);
        pc = 32'h20; #1;
        if (predict_taken !== 1'b0) begin $display("FAIL gshare saturation low"); $finish; end

        do_update(32'h20, 8'h00, 1'b1);
        if (query_history !== 8'h01) begin $display("FAIL gshare history shift"); $finish; end
        pc = 32'h24; #1;
        if (predict_taken !== 1'b0) begin $display("FAIL gshare retained entry under new history"); $finish; end

        do_update(32'h24, 8'h01, 1'b1);
        if (query_history !== 8'h03) begin $display("FAIL gshare second history shift"); $finish; end
        pc = 32'h2c; #1;
        if (predict_taken !== 1'b1) begin $display("FAIL gshare weakly-taken recovery"); $finish; end

        $display("PASS tb_branch_predictor");
        $finish;
    end
endmodule
