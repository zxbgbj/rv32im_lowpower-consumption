// Module: imm_gen.
// Role: immediate generator for I/S/B/U/J instruction formats in ID stage.
// Key ports: instr [31:0], imm [31:0].
// Connections: input from IF/ID instruction word, output to ID/EX register and EX operand selection logic.
module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm
);
    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            7'b0010011,
            7'b0000011,
            7'b1100111:
                imm = {{20{instr[31]}}, instr[31:20]};
            7'b0100011:
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            7'b1100011:
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            7'b0110111,
            7'b0010111:
                imm = {instr[31:12], 12'b0};
            7'b1101111:
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            default:
                imm = 32'd0;
        endcase
    end
endmodule
