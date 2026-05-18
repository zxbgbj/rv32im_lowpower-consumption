// Module: alu.
// Role: combinational ALU used in the EX stage.
// Key ports: operand_a [31:0], operand_b [31:0], alu_ctrl [3:0], result [31:0].
// Connections: driven by EX operand muxes and consumed by ex_stage, EX/MEM, and the forwarding path.
module alu (
    input  wire [3:0]  alu_ctrl,
    input  wire [31:0] op_a,
    input  wire [31:0] op_b,
    output reg  [31:0] result
);
    localparam ALU_ADD  = 4'd0;
    localparam ALU_SUB  = 4'd1;
    localparam ALU_AND  = 4'd2;
    localparam ALU_OR   = 4'd3;
    localparam ALU_XOR  = 4'd4;
    localparam ALU_SLT  = 4'd5;
    localparam ALU_SLTU = 4'd6;
    localparam ALU_SLL  = 4'd7;
    localparam ALU_SRL  = 4'd8;
    localparam ALU_SRA  = 4'd9;
    localparam ALU_PASS = 4'd10;

    always @(*) begin
        case (alu_ctrl)
            ALU_ADD:  result = op_a + op_b;
            ALU_SUB:  result = op_a - op_b;
            ALU_AND:  result = op_a & op_b;
            ALU_OR:   result = op_a | op_b;
            ALU_XOR:  result = op_a ^ op_b;
            ALU_SLT:  result = ($signed(op_a) < $signed(op_b)) ? 32'd1 : 32'd0;
            ALU_SLTU: result = (op_a < op_b) ? 32'd1 : 32'd0;
            ALU_SLL:  result = op_a << op_b[4:0];
            ALU_SRL:  result = op_a >> op_b[4:0];
            ALU_SRA:  result = $signed(op_a) >>> op_b[4:0];
            ALU_PASS: result = op_b;
            default:  result = 32'd0;
        endcase
    end
endmodule
