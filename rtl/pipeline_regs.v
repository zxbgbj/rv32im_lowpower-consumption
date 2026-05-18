// Module: if_id_reg.
// Role: pipeline register between IF and ID stages.
// Key ports: pc_in [31:0], instr_in [31:0], instr_len_in [1:0], predict_taken_in, predict_target_in [31:0].
// Connections: captures front_end outputs and forwards them to decode unless stalled or flushed.
module if_id_reg #(
    parameter PRED_HISTORY_W = 8
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire        flush,
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    input  wire [1:0]  instr_len_in,
    input  wire        instr_is_compressed_in,
    input  wire        predict_taken_in,
    input  wire [31:0] predict_target_in,
    input  wire [PRED_HISTORY_W-1:0] predict_history_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] instr_out,
    output reg  [1:0]  instr_len_out,
    output reg         instr_is_compressed_out,
    output reg         predict_taken_out,
    output reg  [31:0] predict_target_out,
    output reg  [PRED_HISTORY_W-1:0] predict_history_out
);
    localparam NOP = 32'h00000013;

    always @(posedge clk) begin
        if (rst) begin
            pc_out <= 32'd0;
            instr_out <= NOP;
            instr_len_out <= 2'd2;
            instr_is_compressed_out <= 1'b0;
            predict_taken_out <= 1'b0;
            predict_target_out <= 32'd0;
            predict_history_out <= {PRED_HISTORY_W{1'b0}};
        end else if (flush) begin
            pc_out <= 32'd0;
            instr_out <= NOP;
            instr_len_out <= 2'd2;
            instr_is_compressed_out <= 1'b0;
            predict_taken_out <= 1'b0;
            predict_target_out <= 32'd0;
            predict_history_out <= {PRED_HISTORY_W{1'b0}};
        end else if (!stall) begin
            pc_out <= pc_in;
            instr_out <= instr_in;
            instr_len_out <= instr_len_in;
            instr_is_compressed_out <= instr_is_compressed_in;
            predict_taken_out <= predict_taken_in;
            predict_target_out <= predict_target_in;
            predict_history_out <= predict_history_in;
        end
    end
endmodule

// Module: id_ex_reg.
// Role: pipeline register between ID and EX stages.
// Key ports: decode data/control bundle, csr fields, m_op [2:0], mem_size [1:0], predict metadata.
// Connections: captures decoded register values and control signals for ex_stage, m_unit, MEM control, and CSR handling.
module id_ex_reg #(
    parameter PRED_HISTORY_W = 8
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire        flush,
    input  wire [31:0] pc_in,
    input  wire [31:0] rs1_val_in,
    input  wire [31:0] rs2_val_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,
    input  wire [2:0]  funct3_in,
    input  wire [3:0]  alu_ctrl_in,
    input  wire        alu_src_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        reg_write_in,
    input  wire        mem_to_reg_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire        jalr_in,
    input  wire        load_unsigned_in,
    input  wire [1:0]  mem_size_in,
    input  wire        m_valid_in,
    input  wire [2:0]  m_op_in,
    input  wire        predict_taken_in,
    input  wire [31:0] predict_target_in,
    input  wire [PRED_HISTORY_W-1:0] predict_history_in,
    input  wire        csr_valid_in,
    input  wire [2:0]  csr_cmd_in,
    input  wire [11:0] csr_addr_in,
    input  wire        csr_use_imm_in,
    input  wire [31:0] csr_rdata_in,
    input  wire        sys_ecall_in,
    input  wire        sys_ebreak_in,
    input  wire        sys_mret_in,
    input  wire        sys_illegal_in,
    input  wire        fence_i_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] rs1_val_out,
    output reg  [31:0] rs2_val_out,
    output reg  [31:0] imm_out,
    output reg  [4:0]  rs1_out,
    output reg  [4:0]  rs2_out,
    output reg  [4:0]  rd_out,
    output reg  [2:0]  funct3_out,
    output reg  [3:0]  alu_ctrl_out,
    output reg         alu_src_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         reg_write_out,
    output reg         mem_to_reg_out,
    output reg         branch_out,
    output reg         jump_out,
    output reg         jalr_out,
    output reg         load_unsigned_out,
    output reg  [1:0]  mem_size_out,
    output reg         m_valid_out,
    output reg  [2:0]  m_op_out,
    output reg         predict_taken_out,
    output reg  [31:0] predict_target_out,
    output reg  [PRED_HISTORY_W-1:0] predict_history_out,
    output reg         csr_valid_out,
    output reg  [2:0]  csr_cmd_out,
    output reg  [11:0] csr_addr_out,
    output reg         csr_use_imm_out,
    output reg  [31:0] csr_rdata_out,
    output reg         sys_ecall_out,
    output reg         sys_ebreak_out,
    output reg         sys_mret_out,
    output reg         sys_illegal_out,
    output reg         fence_i_out
);
    always @(posedge clk) begin
        if (rst) begin
            pc_out <= 32'd0;
            rs1_val_out <= 32'd0;
            rs2_val_out <= 32'd0;
            imm_out <= 32'd0;
            rs1_out <= 5'd0;
            rs2_out <= 5'd0;
            rd_out <= 5'd0;
            funct3_out <= 3'd0;
            alu_ctrl_out <= 4'd0;
            alu_src_out <= 1'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            reg_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            branch_out <= 1'b0;
            jump_out <= 1'b0;
            jalr_out <= 1'b0;
            load_unsigned_out <= 1'b0;
            mem_size_out <= 2'd2;
            m_valid_out <= 1'b0;
            m_op_out <= 3'd0;
            predict_taken_out <= 1'b0;
            predict_target_out <= 32'd0;
            predict_history_out <= {PRED_HISTORY_W{1'b0}};
            csr_valid_out <= 1'b0;
            csr_cmd_out <= 3'd0;
            csr_addr_out <= 12'd0;
            csr_use_imm_out <= 1'b0;
            csr_rdata_out <= 32'd0;
            sys_ecall_out <= 1'b0;
            sys_ebreak_out <= 1'b0;
            sys_mret_out <= 1'b0;
            sys_illegal_out <= 1'b0;
            fence_i_out <= 1'b0;
        end else if (flush) begin
            pc_out <= 32'd0;
            rs1_val_out <= 32'd0;
            rs2_val_out <= 32'd0;
            imm_out <= 32'd0;
            rs1_out <= 5'd0;
            rs2_out <= 5'd0;
            rd_out <= 5'd0;
            funct3_out <= 3'd0;
            alu_ctrl_out <= 4'd0;
            alu_src_out <= 1'b0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            reg_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            branch_out <= 1'b0;
            jump_out <= 1'b0;
            jalr_out <= 1'b0;
            load_unsigned_out <= 1'b0;
            mem_size_out <= 2'd2;
            m_valid_out <= 1'b0;
            m_op_out <= 3'd0;
            predict_taken_out <= 1'b0;
            predict_target_out <= 32'd0;
            predict_history_out <= {PRED_HISTORY_W{1'b0}};
            csr_valid_out <= 1'b0;
            csr_cmd_out <= 3'd0;
            csr_addr_out <= 12'd0;
            csr_use_imm_out <= 1'b0;
            csr_rdata_out <= 32'd0;
            sys_ecall_out <= 1'b0;
            sys_ebreak_out <= 1'b0;
            sys_mret_out <= 1'b0;
            sys_illegal_out <= 1'b0;
            fence_i_out <= 1'b0;
        end else if (enable) begin
            pc_out <= pc_in;
            rs1_val_out <= rs1_val_in;
            rs2_val_out <= rs2_val_in;
            imm_out <= imm_in;
            rs1_out <= rs1_in;
            rs2_out <= rs2_in;
            rd_out <= rd_in;
            funct3_out <= funct3_in;
            alu_ctrl_out <= alu_ctrl_in;
            alu_src_out <= alu_src_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            branch_out <= branch_in;
            jump_out <= jump_in;
            jalr_out <= jalr_in;
            load_unsigned_out <= load_unsigned_in;
            mem_size_out <= mem_size_in;
            m_valid_out <= m_valid_in;
            m_op_out <= m_op_in;
            predict_taken_out <= predict_taken_in;
            predict_target_out <= predict_target_in;
            predict_history_out <= predict_history_in;
            csr_valid_out <= csr_valid_in;
            csr_cmd_out <= csr_cmd_in;
            csr_addr_out <= csr_addr_in;
            csr_use_imm_out <= csr_use_imm_in;
            csr_rdata_out <= csr_rdata_in;
            sys_ecall_out <= sys_ecall_in;
            sys_ebreak_out <= sys_ebreak_in;
            sys_mret_out <= sys_mret_in;
            sys_illegal_out <= sys_illegal_in;
            fence_i_out <= fence_i_in;
        end
    end
endmodule

// Module: ex_mem_reg.
// Role: pipeline register between EX and MEM stages.
// Key ports: alu_result_in [31:0], store_data_in [31:0], mem control, branch_taken_in, branch_target_in [31:0].
// Connections: holds EX results for mem_stage and the redirect path.
module ex_mem_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire [31:0] pc_in,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] store_data_in,
    input  wire [4:0]  rd_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        reg_write_in,
    input  wire        mem_to_reg_in,
    input  wire [1:0]  mem_size_in,
    input  wire        load_unsigned_in,
    input  wire        control_flow_valid_in,
    input  wire        branch_taken_in,
    input  wire [31:0] branch_target_in,
    output reg  [31:0] pc_out,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] store_data_out,
    output reg  [4:0]  rd_out,
    output reg         mem_read_out,
    output reg         mem_write_out,
    output reg         reg_write_out,
    output reg         mem_to_reg_out,
    output reg  [1:0]  mem_size_out,
    output reg         load_unsigned_out,
    output reg         control_flow_valid_out,
    output reg         branch_taken_out,
    output reg  [31:0] branch_target_out
);
    always @(posedge clk) begin
        if (rst) begin
            pc_out <= 32'd0;
            alu_result_out <= 32'd0;
            store_data_out <= 32'd0;
            rd_out <= 5'd0;
            mem_read_out <= 1'b0;
            mem_write_out <= 1'b0;
            reg_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
            mem_size_out <= 2'd2;
            load_unsigned_out <= 1'b0;
            control_flow_valid_out <= 1'b0;
            branch_taken_out <= 1'b0;
            branch_target_out <= 32'd0;
        end else if (enable) begin
            pc_out <= pc_in;
            alu_result_out <= alu_result_in;
            store_data_out <= store_data_in;
            rd_out <= rd_in;
            mem_read_out <= mem_read_in;
            mem_write_out <= mem_write_in;
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            mem_size_out <= mem_size_in;
            load_unsigned_out <= load_unsigned_in;
            control_flow_valid_out <= control_flow_valid_in;
            branch_taken_out <= branch_taken_in;
            branch_target_out <= branch_target_in;
        end
    end
endmodule

// Module: mem_wb_reg.
// Role: pipeline register between MEM and WB stages.
// Key ports: alu_result_in [31:0], mem_rdata_in [31:0], rd_in [4:0], reg_write_in, mem_to_reg_in.
// Connections: stores final write-back candidates for regfile update in WB stage.
module mem_wb_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,
    input  wire [31:0] alu_result_in,
    input  wire [31:0] mem_rdata_in,
    input  wire [4:0]  rd_in,
    input  wire        reg_write_in,
    input  wire        mem_to_reg_in,
    output reg  [31:0] alu_result_out,
    output reg  [31:0] mem_rdata_out,
    output reg  [4:0]  rd_out,
    output reg         reg_write_out,
    output reg         mem_to_reg_out
);
    always @(posedge clk) begin
        if (rst) begin
            alu_result_out <= 32'd0;
            mem_rdata_out <= 32'd0;
            rd_out <= 5'd0;
            reg_write_out <= 1'b0;
            mem_to_reg_out <= 1'b0;
        end else if (enable) begin
            alu_result_out <= alu_result_in;
            mem_rdata_out <= mem_rdata_in;
            rd_out <= rd_in;
            reg_write_out <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
        end
    end
endmodule


