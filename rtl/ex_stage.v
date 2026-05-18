// Module: ex_stage.
// Role: EX-stage datapath wrapper combining ALU, branch logic, and result selection.
// Key ports: pc [31:0], rs1_val [31:0], rs2_val [31:0], imm [31:0], control inputs, alu_result [31:0].
// Connections: input from ID/EX register and forwarding muxes, output to EX/MEM register and redirect logic.
module ex_stage (
    input  wire [31:0] pc,
    input  wire [31:0] rs1_val,
    input  wire [31:0] rs2_val,
    input  wire [31:0] imm,
    input  wire [3:0]  alu_ctrl,
    input  wire        alu_src,
    input  wire        branch,
    input  wire        jump,
    input  wire        jalr,
    input  wire        is_m,
    input  wire [2:0]  m_op,
    input  wire        m_done,
    input  wire [31:0] m_result,
    input  wire [2:0]  funct3,
    input  wire [1:0]  forward_a_sel,
    input  wire [1:0]  forward_b_sel,
    input  wire [31:0] ex_mem_fwd_data,
    input  wire [31:0] mem_wb_fwd_data,
    input  wire        predict_taken_in,
    input  wire [31:0] predict_target_in,
    input  wire        csr_valid,
    input  wire [2:0]  csr_cmd,
    input  wire        csr_use_imm,
    input  wire [11:0] csr_addr,
    input  wire [31:0] csr_rdata,
    input  wire [4:0]  rs1_addr,
    input  wire        sys_ecall,
    input  wire        sys_ebreak,
    input  wire        sys_mret,
    input  wire        sys_illegal,
    output wire [31:0] alu_result,
    output wire [31:0] store_data,
    output wire        control_flow_valid,
    output wire        branch_taken,
    output wire [31:0] branch_target,
    output wire [31:0] redirect_target,
    output wire        mispredict,
    output wire        csr_write_en,
    output reg  [31:0] csr_write_data,
    output wire [11:0] csr_write_addr,
    output wire        trap_req,
    output wire [31:0] trap_cause,
    output wire        mret_req
);
    localparam ALU_PASS  = 4'd10;
    localparam ALU_AUIPC = 4'd11;

    reg [31:0] fwd_a;
    reg [31:0] fwd_b;
    wire [31:0] alu_rhs = alu_src ? imm : fwd_b;
    wire [31:0] core_alu_result;
    wire        branch_cond_taken;
    wire        actual_taken = jump | branch_cond_taken;
    wire [31:0] pc_plus4 = pc + 32'd4;
    wire [31:0] actual_target = jalr ? ((fwd_a + imm) & 32'hffff_fffe) : (pc + imm);
    wire [31:0] csr_operand = csr_use_imm ? {27'd0, rs1_addr} : fwd_a;
    wire [31:0] trap_cause_int = sys_illegal ? 32'd2 : (sys_ebreak ? 32'd3 : 32'd11);
    wire        predicted_taken_match = !(predict_taken_in ^ actual_taken);
    wire        check_target_mismatch = predict_taken_in && actual_taken;
    wire        predict_target_mismatch = check_target_mismatch && (predict_target_in != actual_target);

    assign csr_write_addr = csr_addr;
    assign csr_write_en = csr_valid && ((csr_cmd == 3'b001) || (csr_cmd == 3'b101) ||
                         (((csr_cmd == 3'b010) || (csr_cmd == 3'b011) || (csr_cmd == 3'b110) || (csr_cmd == 3'b111)) && (csr_operand != 32'd0)));
    assign trap_req = sys_illegal | sys_ecall | sys_ebreak;
    assign trap_cause = trap_cause_int;
    assign mret_req = sys_mret;

    always @(*) begin
        case (forward_a_sel)
            2'b10: fwd_a = ex_mem_fwd_data;
            2'b01: fwd_a = mem_wb_fwd_data;
            default: fwd_a = rs1_val;
        endcase
        case (forward_b_sel)
            2'b10: fwd_b = ex_mem_fwd_data;
            2'b01: fwd_b = mem_wb_fwd_data;
            default: fwd_b = rs2_val;
        endcase

        case (csr_cmd)
            3'b001, 3'b101: csr_write_data = csr_operand;
            3'b010, 3'b110: csr_write_data = csr_rdata | csr_operand;
            3'b011, 3'b111: csr_write_data = csr_rdata & ~csr_operand;
            default: csr_write_data = csr_rdata;
        endcase
    end

    alu alu_u (
        .alu_ctrl(alu_ctrl),
        .op_a(fwd_a),
        .op_b(alu_rhs),
        .result(core_alu_result)
    );

    branch_unit branch_unit_u (
        .branch(branch),
        .funct3(funct3),
        .lhs(fwd_a),
        .rhs(fwd_b),
        .taken(branch_cond_taken)
    );

    assign control_flow_valid = branch || jump;
    assign store_data = fwd_b;
    assign branch_taken = actual_taken;
    assign branch_target = actual_target;
    assign redirect_target = actual_taken ? actual_target : pc_plus4;
    assign alu_result = csr_valid ? csr_rdata :
                        is_m ? m_result :
                        jump ? pc_plus4 :
                        (alu_ctrl == ALU_PASS) ? imm :
                        (alu_ctrl == ALU_AUIPC) ? (pc + imm) :
                        core_alu_result;
    assign mispredict = control_flow_valid &&
                        (!predicted_taken_match || predict_target_mismatch);
endmodule

