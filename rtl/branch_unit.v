// Module: branch_unit.
// Role: branch, jump, and JALR resolution logic for the EX stage.
// Key ports: pc [31:0], rs1 [31:0], rs2 [31:0], imm [31:0], funct3 [2:0], branch, jump, jalr.
// Connections: input from ID/EX register, output branch_taken and branch_target [31:0] to redirect logic.
module branch_unit (
    input  wire        branch,
    input  wire [2:0]  funct3,
    input  wire [31:0] lhs,
    input  wire [31:0] rhs,
    output reg         taken
);
    always @(*) begin
        taken = 1'b0;
        if (branch) begin
            case (funct3)
                3'b000: taken = (lhs == rhs);                    // BEQ
                3'b001: taken = (lhs != rhs);                    // BNE
                3'b100: taken = ($signed(lhs) < $signed(rhs));   // BLT
                3'b101: taken = ($signed(lhs) >= $signed(rhs));  // BGE
                3'b110: taken = (lhs < rhs);                     // BLTU
                3'b111: taken = (lhs >= rhs);                    // BGEU
                default: taken = 1'b0;
            endcase
        end
    end
endmodule
