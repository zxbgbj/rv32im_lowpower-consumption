// Module: pc_manager.
// Role: next-PC selector for sequential fetch, prediction, redirect, and trap entry.
// Key ports: current_pc [31:0], predict_taken, predict_target [31:0], redirect_valid, redirect_pc [31:0], next_pc [31:0].
// Connections: used inside front_end between predictor outputs and instruction memory address generation.
module pc_manager (
    input  wire [31:0] current_pc,
    input  wire [31:0] seq_pc,
    input  wire        predict_taken,
    input  wire [31:0] predict_target,
    input  wire        redirect_valid,
    input  wire [31:0] redirect_pc,
    output wire [31:0] next_pc
);
    assign next_pc = redirect_valid ? redirect_pc :
                     (predict_taken ? predict_target : seq_pc);
endmodule
