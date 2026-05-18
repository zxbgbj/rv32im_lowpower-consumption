// Module: wb_stage.
// Role: final write-back data selector.
// Key ports: alu_result [31:0], mem_rdata [31:0], mem_to_reg, wb_data [31:0].
// Connections: input from MEM/WB register and output to regfile write-back port.
module wb_stage (
    input  wire [31:0] alu_result,
    input  wire [31:0] mem_rdata,
    input  wire        mem_to_reg,
    output wire [31:0] wb_data
);
    assign wb_data = mem_to_reg ? mem_rdata : alu_result;
endmodule
