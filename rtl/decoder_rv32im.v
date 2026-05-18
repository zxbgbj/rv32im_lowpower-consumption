// Module: decoder_rv32im.
// Role: instruction decoder for RV32I, RV32M, and minimal system/CSR operations in ID stage.
// Key ports: instr [31:0], control outputs, mem_size [1:0], csr_addr [11:0], m_op [2:0].
// Connections: input from IF/ID register, outputs drive hazard logic, EX controls, MEM controls, and CSR/M-unit selects.
module decoder_rv32im (
    input  wire [31:0] instr,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [4:0]  rd,
    output wire [2:0]  funct3,
    output reg  [3:0]  alu_ctrl,
    output reg         alu_src,
    output reg         mem_read,
    output reg         mem_write,
    output reg         reg_write,
    output reg         mem_to_reg,
    output reg         branch,
    output reg         jump,
    output reg         jalr,
    output reg         uses_rs1,
    output reg         uses_rs2,
    output reg         illegal,
    output reg         load_unsigned,
    output reg  [1:0]  mem_size,
    output reg         m_valid,
    output reg  [2:0]  m_op,
    output reg         csr_valid,
    output reg  [2:0]  csr_cmd,
    output reg  [11:0] csr_addr,
    output reg         csr_use_imm,
    output reg         sys_ecall,
    output reg         sys_ebreak,
    output reg         sys_mret,
    output reg         fence_i
);
    localparam ALU_ADD   = 4'd0;
    localparam ALU_SUB   = 4'd1;
    localparam ALU_AND   = 4'd2;
    localparam ALU_OR    = 4'd3;
    localparam ALU_XOR   = 4'd4;
    localparam ALU_SLT   = 4'd5;
    localparam ALU_SLTU  = 4'd6;
    localparam ALU_SLL   = 4'd7;
    localparam ALU_SRL   = 4'd8;
    localparam ALU_SRA   = 4'd9;
    localparam ALU_PASS  = 4'd10;
    localparam ALU_AUIPC = 4'd11;

    wire [6:0] opcode = instr[6:0];
    wire [6:0] funct7 = instr[31:25];
    wire [11:0] sys_imm = instr[31:20];

    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd = instr[11:7];
    assign funct3 = instr[14:12];

    always @(*) begin
        alu_ctrl      = ALU_ADD;
        alu_src       = 1'b0;
        mem_read      = 1'b0;
        mem_write     = 1'b0;
        reg_write     = 1'b0;
        mem_to_reg    = 1'b0;
        branch        = 1'b0;
        jump          = 1'b0;
        jalr          = 1'b0;
        uses_rs1      = 1'b0;
        uses_rs2      = 1'b0;
        illegal       = 1'b0;
        load_unsigned = 1'b0;
        mem_size      = 2'd2;
        m_valid       = 1'b0;
        m_op          = 3'd0;
        csr_valid     = 1'b0;
        csr_cmd       = 3'd0;
        csr_addr      = instr[31:20];
        csr_use_imm   = 1'b0;
        sys_ecall     = 1'b0;
        sys_ebreak    = 1'b0;
        sys_mret      = 1'b0;
        fence_i       = 1'b0;

        case (opcode)
            7'b0110011: begin
                reg_write = 1'b1;
                uses_rs1  = 1'b1;
                uses_rs2  = 1'b1;
                if (funct7 == 7'b0000001) begin
                    m_valid = 1'b1;
                    case (funct3)
                        3'b000: m_op = 3'd0;
                        3'b001: m_op = 3'd1;
                        3'b010: m_op = 3'd2;
                        3'b011: m_op = 3'd3;
                        3'b100: m_op = 3'd4;
                        3'b101: m_op = 3'd5;
                        3'b110: m_op = 3'd6;
                        3'b111: m_op = 3'd7;
                        default: illegal = 1'b1;
                    endcase
                end else begin
                    case (funct3)
                        3'b000: alu_ctrl = funct7[5] ? ALU_SUB : ALU_ADD;
                        3'b001: alu_ctrl = ALU_SLL;
                        3'b010: alu_ctrl = ALU_SLT;
                        3'b011: alu_ctrl = ALU_SLTU;
                        3'b100: alu_ctrl = ALU_XOR;
                        3'b101: alu_ctrl = funct7[5] ? ALU_SRA : ALU_SRL;
                        3'b110: alu_ctrl = ALU_OR;
                        3'b111: alu_ctrl = ALU_AND;
                        default: illegal = 1'b1;
                    endcase
                end
            end
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                uses_rs1  = 1'b1;
                case (funct3)
                    3'b000: alu_ctrl = ALU_ADD;
                    3'b010: alu_ctrl = ALU_SLT;
                    3'b011: alu_ctrl = ALU_SLTU;
                    3'b100: alu_ctrl = ALU_XOR;
                    3'b110: alu_ctrl = ALU_OR;
                    3'b111: alu_ctrl = ALU_AND;
                    3'b001: begin
                        alu_ctrl = ALU_SLL;
                        if (instr[31:25] != 7'b0000000) illegal = 1'b1;
                    end
                    3'b101: begin
                        alu_ctrl = instr[30] ? ALU_SRA : ALU_SRL;
                        if ((instr[31:25] != 7'b0000000) && (instr[31:25] != 7'b0100000)) illegal = 1'b1;
                    end
                    default: illegal = 1'b1;
                endcase
            end
            7'b0000011: begin
                reg_write   = 1'b1;
                alu_src     = 1'b1;
                mem_read    = 1'b1;
                mem_to_reg  = 1'b1;
                uses_rs1    = 1'b1;
                case (funct3)
                    3'b000: begin mem_size = 2'd0; load_unsigned = 1'b0; end
                    3'b001: begin mem_size = 2'd1; load_unsigned = 1'b0; end
                    3'b010: begin mem_size = 2'd2; load_unsigned = 1'b0; end
                    3'b100: begin mem_size = 2'd0; load_unsigned = 1'b1; end
                    3'b101: begin mem_size = 2'd1; load_unsigned = 1'b1; end
                    default: illegal = 1'b1;
                endcase
            end
            7'b0100011: begin
                alu_src   = 1'b1;
                mem_write = 1'b1;
                uses_rs1  = 1'b1;
                uses_rs2  = 1'b1;
                case (funct3)
                    3'b000: mem_size = 2'd0;
                    3'b001: mem_size = 2'd1;
                    3'b010: mem_size = 2'd2;
                    default: illegal = 1'b1;
                endcase
            end
            7'b1100011: begin
                branch   = 1'b1;
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
                case (funct3)
                    3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111: begin end
                    default: illegal = 1'b1;
                endcase
            end
            7'b1101111: begin
                jump      = 1'b1;
                reg_write = 1'b1;
            end
            7'b1100111: begin
                jump      = 1'b1;
                jalr      = 1'b1;
                reg_write = 1'b1;
                alu_src   = 1'b1;
                uses_rs1  = 1'b1;
                if (funct3 != 3'b000) illegal = 1'b1;
            end
            7'b0110111: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = ALU_PASS;
            end
            7'b0010111: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = ALU_AUIPC;
            end
            7'b0001111: begin
                fence_i = (funct3 == 3'b001);
                illegal = 1'b0;
            end
            7'b1110011: begin
                case (funct3)
                    3'b000: begin
                        case (sys_imm)
                            12'h000: sys_ecall = 1'b1;
                            12'h001: sys_ebreak = 1'b1;
                            12'h302: sys_mret = 1'b1;
                            default: illegal = 1'b1;
                        endcase
                    end
                    3'b001, 3'b010, 3'b011, 3'b101, 3'b110, 3'b111: begin
                        csr_valid   = 1'b1;
                        csr_cmd     = funct3;
                        csr_use_imm = funct3[2];
                        reg_write   = 1'b1;
                        uses_rs1    = !funct3[2] && (rs1 != 5'd0);
                    end
                    default: illegal = 1'b1;
                endcase
            end
            default: illegal = 1'b1;
        endcase
    end
endmodule

