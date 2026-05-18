`include "memory_profile.vh"

// Module: cpu_top.
// Role: top-level 5-stage single-issue RV32IM CPU with low-power enables.
// Key ports: instruction/data memory interfaces, fetch/debug outputs, trap outputs, and M-unit status.
// Connections: instantiates IF/ID/EX/MEM/WB datapath blocks, predictor blocks, BRAM blocks, CSR file, and pipeline registers.
module cpu_top #(
    parameter IMEM_FILE = "mem/program.hex",
    parameter DMEM_FILE = "",
    parameter BHT_ENTRIES = 1024,
    parameter BTB_ENTRIES = 256,
    parameter RAS_DEPTH = 16,
    parameter PRED_HISTORY_BITS = 8
) (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] imem_addr,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_we,
    output wire        fetch_valid,
    output wire [31:0] fetch_pc,
    output wire        predict_taken,
    output wire [31:0] predict_target,
    output wire        redirect_valid,
    output wire [31:0] redirect_pc,
    output wire [31:0] instr32,
    output wire [1:0]  instr_len,
    output wire        instr_is_compressed,
    output wire        issue_allow,
    output wire        ex_busy,
    output wire        ex_done,
    output wire        trap_valid,
    output wire [31:0] trap_pc,
    output wire        issue_stall,
    output wire        m_busy,
    output wire        m_done
);
    wire        fe_fetch_valid;
    wire [31:0] fe_fetch_pc;
    wire [31:0] fe_instr32;
    wire [1:0]  fe_instr_len;
    wire        fe_instr_is_compressed;
    wire        fe_predict_taken;
    wire [31:0] fe_predict_target;
    wire [PRED_HISTORY_BITS-1:0] fe_predict_history;
    wire [31:0] fe_imem_addr;
    wire        fe_imem_en;

    wire [31:0] if_id_pc;
    wire [31:0] if_id_instr;
    wire [1:0]  if_id_instr_len;
    wire        if_id_instr_is_compressed;
    wire        if_id_predict_taken;
    wire [31:0] if_id_predict_target;
    wire [PRED_HISTORY_BITS-1:0] if_id_predict_history;

    wire [4:0]  id_rs1;
    wire [4:0]  id_rs2;
    wire [4:0]  id_rd;
    wire [2:0]  id_funct3;
    wire [31:0] id_imm;
    wire [3:0]  id_alu_ctrl;
    wire        id_alu_src;
    wire        id_mem_read;
    wire        id_mem_write;
    wire        id_reg_write;
    wire        id_mem_to_reg;
    wire        id_branch;
    wire        id_jump;
    wire        id_jalr;
    wire        id_uses_rs1;
    wire        id_uses_rs2;
    wire        id_illegal;
    wire        id_load_unsigned;
    wire [1:0]  id_mem_size;
    wire        id_m_valid;
    wire [2:0]  id_m_op;
    wire        id_csr_valid;
    wire [2:0]  id_csr_cmd;
    wire [11:0] id_csr_addr;
    wire        id_csr_use_imm;
    wire        id_sys_ecall;
    wire        id_sys_ebreak;
    wire        id_sys_mret;
    wire        id_fence_i;
    wire [31:0] id_csr_rdata;
    wire [31:0] id_csr_rdata_bypass;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    wire [31:0] id_ex_pc;
    wire [31:0] id_ex_rs1_val;
    wire [31:0] id_ex_rs2_val;
    wire [31:0] id_ex_imm;
    wire [4:0]  id_ex_rs1;
    wire [4:0]  id_ex_rs2;
    wire [4:0]  id_ex_rd;
    wire [2:0]  id_ex_funct3;
    wire [3:0]  id_ex_alu_ctrl;
    wire        id_ex_alu_src;
    wire        id_ex_mem_read;
    wire        id_ex_mem_write;
    wire        id_ex_reg_write;
    wire        id_ex_mem_to_reg;
    wire        id_ex_branch;
    wire        id_ex_jump;
    wire        id_ex_jalr;
    wire        id_ex_load_unsigned;
    wire [1:0]  id_ex_mem_size;
    wire        id_ex_m_valid;
    wire [2:0]  id_ex_m_op;
    wire        id_ex_predict_taken;
    wire [31:0] id_ex_predict_target;
    wire [PRED_HISTORY_BITS-1:0] id_ex_predict_history;
    wire        id_ex_csr_valid;
    wire [2:0]  id_ex_csr_cmd;
    wire [11:0] id_ex_csr_addr;
    wire        id_ex_csr_use_imm;
    wire [31:0] id_ex_csr_rdata;
    wire        id_ex_sys_ecall;
    wire        id_ex_sys_ebreak;
    wire        id_ex_sys_mret;
    wire        id_ex_sys_illegal;
    wire        id_ex_fence_i;

    wire [1:0]  forward_a;
    wire [1:0]  forward_b;
    wire [31:0] ex_alu_result;
    wire [31:0] ex_store_data;
    wire        ex_branch_taken;
    wire [31:0] ex_branch_target;
    wire        ex_mispredict;
    wire        ex_csr_write_en;
    wire [31:0] ex_csr_write_data;
    wire [11:0] ex_csr_write_addr;
    wire        ex_csr_commit_en;
    wire        ex_trap_req;
    wire [31:0] ex_trap_cause;
    wire        ex_mret_req;

    wire [31:0] ex_mem_pc;
    wire [31:0] ex_mem_alu_result;
    wire [31:0] ex_mem_store_data;
    wire [4:0]  ex_mem_rd;
    wire        ex_mem_mem_read;
    wire        ex_mem_mem_write;
    wire        ex_mem_reg_write;
    wire        ex_mem_mem_to_reg;
    wire [1:0]  ex_mem_mem_size;
    wire        ex_mem_load_unsigned;
    wire        ex_mem_branch_taken;
    wire [31:0] ex_mem_branch_target;

    wire [31:0] dmem_rdata;
    wire [31:0] mem_load_data;
    reg  [31:0] ex_src_a;
    reg  [31:0] ex_src_b;

    wire [31:0] mem_wb_alu_result;
    wire [31:0] mem_wb_mem_rdata;
    wire [4:0]  mem_wb_rd;
    wire        mem_wb_reg_write;
    wire        mem_wb_mem_to_reg;
    wire [31:0] wb_data;

    wire hazard_stall;
    wire if_id_stall;
    wire m_start;
    wire [31:0] m_result;
    wire m_result_valid;
    reg  m_inflight;
    reg  mem_read_pending;
    wire m_wait;
    wire mem_wait;
    wire front_stall;
    wire id_ex_enable;
    wire id_ex_flush;
    wire predictor_update_valid;
    wire predictor_update_is_call;
    wire predictor_update_is_return;
    wire [31:0] predictor_update_return_addr;
    wire trap_enter;
    wire mret_commit;
    wire [31:0] csr_mtvec;
    wire [31:0] csr_mepc;
    wire [31:0] csr_mcause;
    wire [31:0] csr_mstatus;
    wire        ex_control_flow_valid;
    wire [31:0] ex_redirect_target;
    wire [31:0] csr_mepc_resume_pc;
    wire        trap_redirect_valid;
    wire        mret_redirect_valid;
    wire        branch_redirect_valid;
    wire        fence_i_redirect_valid;
    wire        id_direct_jump;
    wire [31:0] id_direct_jump_target;
    wire        id_direct_jump_redirect_valid;
    wire        pipeline_wait;
    wire        control_stall;
    wire        frontend_redirect_valid;
    wire        pipeline_redirect_valid;
    wire [31:0] id_ex_pc_plus4;
    wire [31:0] fast_redirect_pc;
    wire        imem_patch_en;
    wire        id_predict_taken_eff;
    wire [31:0] id_predict_target_eff;

    assign imem_addr = fe_imem_addr;
    assign fetch_valid = fe_fetch_valid;
    assign fetch_pc = fe_fetch_pc;
    assign instr32 = fe_instr32;
    assign instr_len = fe_instr_len;
    assign instr_is_compressed = fe_instr_is_compressed;
    assign predict_taken = fe_predict_taken;
    assign predict_target = fe_predict_target;
    assign pipeline_wait = m_wait || mem_wait;
    assign control_stall = hazard_stall || pipeline_wait;
    assign trap_redirect_valid = ex_trap_req && !m_wait;
    assign mret_redirect_valid = ex_mret_req && !m_wait;
    assign branch_redirect_valid = ex_mispredict && !m_wait;
    assign fence_i_redirect_valid = id_ex_fence_i && !pipeline_wait;
    assign id_direct_jump = id_jump && !id_jalr;
    assign id_direct_jump_target = if_id_pc + id_imm;
    assign id_direct_jump_redirect_valid = id_direct_jump && !control_stall &&
                                          (!if_id_predict_taken || (if_id_predict_target != id_direct_jump_target));
    assign id_ex_pc_plus4 = id_ex_pc + 32'd4;
    assign fast_redirect_pc = trap_redirect_valid ? csr_mtvec :
                              (mret_redirect_valid ? csr_mepc_resume_pc :
                              ex_redirect_target);
    assign trap_enter = trap_redirect_valid;
    assign mret_commit = mret_redirect_valid;
    assign pipeline_redirect_valid = trap_redirect_valid || mret_redirect_valid ||
                                     branch_redirect_valid || fence_i_redirect_valid;
    assign frontend_redirect_valid = pipeline_redirect_valid || id_direct_jump_redirect_valid;
    assign redirect_valid = frontend_redirect_valid;
    assign csr_mepc_resume_pc = csr_mepc + 32'd4;
    // Split the fast redirect target from the fence.i fallthrough case so the
    // control-path mux stays shallow on the common trap/mret/branch recovery path.
    assign redirect_pc = (trap_redirect_valid || mret_redirect_valid || branch_redirect_valid) ?
                         fast_redirect_pc :
                         (fence_i_redirect_valid ? id_ex_pc_plus4 : id_direct_jump_target);
    assign trap_valid = trap_enter;
    assign trap_pc = id_ex_pc;

    assign m_start = id_ex_m_valid && !m_busy && !m_inflight;
    assign m_wait = id_ex_m_valid && !m_done;
    assign mem_wait = ex_mem_mem_read && !mem_read_pending;
    assign ex_busy = m_wait;
    assign ex_done = m_done;

    assign front_stall = control_stall;
    assign if_id_stall = front_stall || !fe_fetch_valid;
    assign issue_stall = front_stall;
    assign issue_allow = !front_stall;
    assign id_ex_enable = !m_wait && !mem_wait;
    assign id_ex_flush = (hazard_stall || pipeline_redirect_valid) && !pipeline_wait;
    assign predictor_update_valid = !(m_wait || mem_wait) && (id_ex_branch || id_ex_jump);
    assign predictor_update_is_call = id_ex_jump && ((id_ex_rd == 5'd1) || (id_ex_rd == 5'd5));
    assign predictor_update_is_return = id_ex_jalr && (id_ex_rd == 5'd0) &&
                                        ((id_ex_rs1 == 5'd1) || (id_ex_rs1 == 5'd5)) &&
                                        (id_ex_imm == 32'd0);
    assign predictor_update_return_addr = id_ex_pc_plus4;
    assign id_predict_taken_eff = id_direct_jump ? 1'b1 : if_id_predict_taken;
    assign id_predict_target_eff = id_direct_jump ? id_direct_jump_target : if_id_predict_target;
    assign ex_csr_commit_en = ex_csr_write_en && !m_wait && !ex_trap_req && !ex_mret_req;
    assign id_csr_rdata_bypass = (ex_csr_commit_en && (ex_csr_write_addr == id_csr_addr)) ? ex_csr_write_data : id_csr_rdata;
    assign imem_patch_en = ex_mem_mem_write && (dmem_addr[31:2] < `RV32IM_IMEM_DEPTH_WORDS);

    front_end #(
        .IMEM_FILE(IMEM_FILE),
        .BHT_ENTRIES(BHT_ENTRIES),
        .BTB_ENTRIES(BTB_ENTRIES),
        .RAS_DEPTH(RAS_DEPTH),
        .HISTORY_BITS(PRED_HISTORY_BITS)
    ) front_end_u (
        .clk(clk),
        .rst(rst),
        .stall(front_stall),
        .redirect_valid(frontend_redirect_valid),
        .redirect_pc(redirect_pc),
        .pred_update_valid(predictor_update_valid),
        .pred_update_pc(id_ex_pc),
        .pred_update_taken(ex_branch_taken),
        .pred_update_target(ex_branch_target),
        .pred_update_is_uncond(id_ex_jump),
        .pred_update_is_call(predictor_update_is_call),
        .pred_update_is_return(predictor_update_is_return),
        .pred_update_return_addr(predictor_update_return_addr),
        .pred_update_history(id_ex_predict_history),
        .imem_write_en(imem_patch_en),
        .imem_write_we(dmem_we),
        .imem_write_addr(dmem_addr),
        .imem_write_data(dmem_wdata),
        .fetch_pc(fe_fetch_pc),
        .instr32(fe_instr32),
        .instr_is_compressed(fe_instr_is_compressed),
        .instr_len(fe_instr_len),
        .predict_taken(fe_predict_taken),
        .predict_target(fe_predict_target),
        .predict_history(fe_predict_history),
        .fetch_valid(fe_fetch_valid),
        .imem_addr_debug(fe_imem_addr),
        .imem_en(fe_imem_en)
    );

    if_id_reg #(
        .PRED_HISTORY_W(PRED_HISTORY_BITS)
    ) if_id_reg_u (
        .clk(clk),
        .rst(rst),
        .stall(if_id_stall),
        .flush(frontend_redirect_valid),
        .pc_in(fe_fetch_pc),
        .instr_in(fe_instr32),
        .instr_len_in(fe_instr_len),
        .instr_is_compressed_in(fe_instr_is_compressed),
        .predict_taken_in(fe_predict_taken),
        .predict_target_in(fe_predict_target),
        .predict_history_in(fe_predict_history),
        .pc_out(if_id_pc),
        .instr_out(if_id_instr),
        .instr_len_out(if_id_instr_len),
        .instr_is_compressed_out(if_id_instr_is_compressed),
        .predict_taken_out(if_id_predict_taken),
        .predict_target_out(if_id_predict_target),
        .predict_history_out(if_id_predict_history)
    );

    imm_gen imm_gen_u (
        .instr(if_id_instr),
        .imm(id_imm)
    );

    decoder_rv32im decoder_rv32im_u (
        .instr(if_id_instr),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(id_rd),
        .funct3(id_funct3),
        .alu_ctrl(id_alu_ctrl),
        .alu_src(id_alu_src),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .reg_write(id_reg_write),
        .mem_to_reg(id_mem_to_reg),
        .branch(id_branch),
        .jump(id_jump),
        .jalr(id_jalr),
        .uses_rs1(id_uses_rs1),
        .uses_rs2(id_uses_rs2),
        .illegal(id_illegal),
        .load_unsigned(id_load_unsigned),
        .mem_size(id_mem_size),
        .m_valid(id_m_valid),
        .m_op(id_m_op),
        .csr_valid(id_csr_valid),
        .csr_cmd(id_csr_cmd),
        .csr_addr(id_csr_addr),
        .csr_use_imm(id_csr_use_imm),
        .sys_ecall(id_sys_ecall),
        .sys_ebreak(id_sys_ebreak),
        .sys_mret(id_sys_mret),
        .fence_i(id_fence_i)
    );

    csr_file csr_file_u (
        .clk(clk),
        .rst(rst),
        .read_addr(id_csr_addr),
        .read_data(id_csr_rdata),
        .write_en(ex_csr_commit_en),
        .write_addr(ex_csr_write_addr),
        .write_data(ex_csr_write_data),
        .trap_enter(trap_enter),
        .trap_pc(id_ex_pc),
        .trap_cause(ex_trap_cause),
        .mtvec(csr_mtvec),
        .mepc(csr_mepc),
        .mcause(csr_mcause),
        .mstatus(csr_mstatus)
    );

    regfile regfile_u (
        .clk(clk),
        .rst(rst),
        .rs1_addr(id_rs1),
        .rs2_addr(id_rs2),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .we(mem_wb_reg_write),
        .rd_addr(mem_wb_rd),
        .rd_data(wb_data)
    );

    hazard_unit hazard_unit_u (
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_rd(id_ex_rd),
        .ex_mem_mem_read(ex_mem_mem_read),
        .ex_mem_rd(ex_mem_rd),
        .if_id_rs1(id_rs1),
        .if_id_rs2(id_rs2),
        .if_id_uses_rs1(id_uses_rs1),
        .if_id_uses_rs2(id_uses_rs2),
        .stall(hazard_stall)
    );

    id_ex_reg #(
        .PRED_HISTORY_W(PRED_HISTORY_BITS)
    ) id_ex_reg_u (
        .clk(clk),
        .rst(rst),
        .enable(id_ex_enable),
        .flush(id_ex_flush),
        .pc_in(if_id_pc),
        .rs1_val_in(rs1_data),
        .rs2_val_in(rs2_data),
        .imm_in(id_imm),
        .rs1_in(id_rs1),
        .rs2_in(id_rs2),
        .rd_in(id_rd),
        .funct3_in(id_funct3),
        .alu_ctrl_in(id_alu_ctrl),
        .alu_src_in(id_alu_src),
        .mem_read_in(id_mem_read),
        .mem_write_in(id_mem_write),
        .reg_write_in(id_reg_write),
        .mem_to_reg_in(id_mem_to_reg),
        .branch_in(id_branch),
        .jump_in(id_jump),
        .jalr_in(id_jalr),
        .load_unsigned_in(id_load_unsigned),
        .mem_size_in(id_mem_size),
        .m_valid_in(id_m_valid),
        .m_op_in(id_m_op),
        .predict_taken_in(id_predict_taken_eff),
        .predict_target_in(id_predict_target_eff),
        .predict_history_in(if_id_predict_history),
        .csr_valid_in(id_csr_valid),
        .csr_cmd_in(id_csr_cmd),
        .csr_addr_in(id_csr_addr),
        .csr_use_imm_in(id_csr_use_imm),
        .csr_rdata_in(id_csr_rdata_bypass),
        .sys_ecall_in(id_sys_ecall),
        .sys_ebreak_in(id_sys_ebreak),
        .sys_mret_in(id_sys_mret),
        .sys_illegal_in(id_illegal),
        .fence_i_in(id_fence_i),
        .pc_out(id_ex_pc),
        .rs1_val_out(id_ex_rs1_val),
        .rs2_val_out(id_ex_rs2_val),
        .imm_out(id_ex_imm),
        .rs1_out(id_ex_rs1),
        .rs2_out(id_ex_rs2),
        .rd_out(id_ex_rd),
        .funct3_out(id_ex_funct3),
        .alu_ctrl_out(id_ex_alu_ctrl),
        .alu_src_out(id_ex_alu_src),
        .mem_read_out(id_ex_mem_read),
        .mem_write_out(id_ex_mem_write),
        .reg_write_out(id_ex_reg_write),
        .mem_to_reg_out(id_ex_mem_to_reg),
        .branch_out(id_ex_branch),
        .jump_out(id_ex_jump),
        .jalr_out(id_ex_jalr),
        .load_unsigned_out(id_ex_load_unsigned),
        .mem_size_out(id_ex_mem_size),
        .m_valid_out(id_ex_m_valid),
        .m_op_out(id_ex_m_op),
        .predict_taken_out(id_ex_predict_taken),
        .predict_target_out(id_ex_predict_target),
        .predict_history_out(id_ex_predict_history),
        .csr_valid_out(id_ex_csr_valid),
        .csr_cmd_out(id_ex_csr_cmd),
        .csr_addr_out(id_ex_csr_addr),
        .csr_use_imm_out(id_ex_csr_use_imm),
        .csr_rdata_out(id_ex_csr_rdata),
        .sys_ecall_out(id_ex_sys_ecall),
        .sys_ebreak_out(id_ex_sys_ebreak),
        .sys_mret_out(id_ex_sys_mret),
        .sys_illegal_out(id_ex_sys_illegal),
        .fence_i_out(id_ex_fence_i)
    );

    always @(*) begin
        case (forward_a)
            2'b10: ex_src_a = ex_mem_alu_result;
            2'b01: ex_src_a = wb_data;
            default: ex_src_a = id_ex_rs1_val;
        endcase
        case (forward_b)
            2'b10: ex_src_b = ex_mem_alu_result;
            2'b01: ex_src_b = wb_data;
            default: ex_src_b = id_ex_rs2_val;
        endcase
    end

    forward_unit forward_unit_u (
        .id_ex_rs1(id_ex_rs1),
        .id_ex_rs2(id_ex_rs2),
        .ex_mem_rd(ex_mem_rd),
        .ex_mem_reg_write(ex_mem_reg_write),
        .mem_wb_rd(mem_wb_rd),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    m_unit m_unit_u (
        .clk(clk),
        .rst(rst),
        .enable(id_ex_m_valid || m_busy),
        .start(m_start),
        .op(id_ex_m_op),
        .lhs(ex_src_a),
        .rhs(ex_src_b),
        .busy(m_busy),
        .done(m_done),
        .result_valid(m_result_valid),
        .result(m_result)
    );

    always @(posedge clk) begin
        if (rst || frontend_redirect_valid || !id_ex_m_valid) begin
            m_inflight <= 1'b0;
        end else if (m_start) begin
            m_inflight <= 1'b1;
        end else if (m_done) begin
            m_inflight <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            mem_read_pending <= 1'b0;
        end else if (ex_mem_mem_read && !mem_read_pending) begin
            mem_read_pending <= 1'b1;
        end else begin
            mem_read_pending <= 1'b0;
        end
    end

    ex_stage ex_stage_u (
        .pc(id_ex_pc),
        .rs1_val(id_ex_rs1_val),
        .rs2_val(id_ex_rs2_val),
        .imm(id_ex_imm),
        .alu_ctrl(id_ex_alu_ctrl),
        .alu_src(id_ex_alu_src),
        .branch(id_ex_branch),
        .jump(id_ex_jump),
        .jalr(id_ex_jalr),
        .is_m(id_ex_m_valid),
        .m_op(id_ex_m_op),
        .m_done(m_done),
        .m_result(m_result),
        .funct3(id_ex_funct3),
        .forward_a_sel(forward_a),
        .forward_b_sel(forward_b),
        .ex_mem_fwd_data(ex_mem_alu_result),
        .mem_wb_fwd_data(wb_data),
        .predict_taken_in(id_ex_predict_taken),
        .predict_target_in(id_ex_predict_target),
        .csr_valid(id_ex_csr_valid),
        .csr_cmd(id_ex_csr_cmd),
        .csr_use_imm(id_ex_csr_use_imm),
        .csr_addr(id_ex_csr_addr),
        .csr_rdata(id_ex_csr_rdata),
        .rs1_addr(id_ex_rs1),
        .sys_ecall(id_ex_sys_ecall),
        .sys_ebreak(id_ex_sys_ebreak),
        .sys_mret(id_ex_sys_mret),
        .sys_illegal(id_ex_sys_illegal),
        .alu_result(ex_alu_result),
        .store_data(ex_store_data),
        .control_flow_valid(ex_control_flow_valid),
        .branch_taken(ex_branch_taken),
        .branch_target(ex_branch_target),
        .redirect_target(ex_redirect_target),
        .mispredict(ex_mispredict),
        .csr_write_en(ex_csr_write_en),
        .csr_write_data(ex_csr_write_data),
        .csr_write_addr(ex_csr_write_addr),
        .trap_req(ex_trap_req),
        .trap_cause(ex_trap_cause),
        .mret_req(ex_mret_req)
    );

    ex_mem_reg ex_mem_reg_u (
        .clk(clk),
        .rst(rst),
        .enable(!mem_wait),
        .pc_in(id_ex_pc),
        .alu_result_in(ex_alu_result),
        .store_data_in(ex_store_data),
        .rd_in(m_wait ? 5'd0 : id_ex_rd),
        .mem_read_in(m_wait ? 1'b0 : id_ex_mem_read),
        .mem_write_in(m_wait ? 1'b0 : id_ex_mem_write),
        .reg_write_in(m_wait ? 1'b0 : id_ex_reg_write),
        .mem_to_reg_in(m_wait ? 1'b0 : id_ex_mem_to_reg),
        .mem_size_in(id_ex_mem_size),
        .load_unsigned_in(id_ex_load_unsigned),
        .control_flow_valid_in(m_wait ? 1'b0 : ex_control_flow_valid),
        .branch_taken_in(m_wait ? 1'b0 : ex_branch_taken),
        .branch_target_in(ex_branch_target),
        .pc_out(ex_mem_pc),
        .alu_result_out(ex_mem_alu_result),
        .store_data_out(ex_mem_store_data),
        .rd_out(ex_mem_rd),
        .mem_read_out(ex_mem_mem_read),
        .mem_write_out(ex_mem_mem_write),
        .reg_write_out(ex_mem_reg_write),
        .mem_to_reg_out(ex_mem_mem_to_reg),
        .mem_size_out(ex_mem_mem_size),
        .load_unsigned_out(ex_mem_load_unsigned),
        .control_flow_valid_out(),
        .branch_taken_out(ex_mem_branch_taken),
        .branch_target_out(ex_mem_branch_target)
    );

    dmem_bram #(.MEM_FILE(DMEM_FILE), .DEPTH_WORDS(`RV32IM_DMEM_DEPTH_WORDS)) dmem_bram_u (
        .clk(clk),
        .en(ex_mem_mem_read || ex_mem_mem_write),
        .addr(dmem_addr),
        .wdata(dmem_wdata),
        .we(dmem_we),
        .rdata(dmem_rdata)
    );

    mem_stage mem_stage_u (
        .alu_result(ex_mem_alu_result),
        .store_data(ex_mem_store_data),
        .mem_read(ex_mem_mem_read),
        .mem_write(ex_mem_mem_write),
        .mem_size(ex_mem_mem_size),
        .load_unsigned(ex_mem_load_unsigned),
        .dmem_rdata(dmem_rdata),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .load_data(mem_load_data)
    );

    mem_wb_reg mem_wb_reg_u (
        .clk(clk),
        .rst(rst),
        .enable(!mem_wait),
        .alu_result_in(ex_mem_alu_result),
        .mem_rdata_in(mem_load_data),
        .rd_in(ex_mem_rd),
        .reg_write_in(ex_mem_reg_write),
        .mem_to_reg_in(ex_mem_mem_to_reg),
        .alu_result_out(mem_wb_alu_result),
        .mem_rdata_out(mem_wb_mem_rdata),
        .rd_out(mem_wb_rd),
        .reg_write_out(mem_wb_reg_write),
        .mem_to_reg_out(mem_wb_mem_to_reg)
    );

    wb_stage wb_stage_u (
        .alu_result(mem_wb_alu_result),
        .mem_rdata(mem_wb_mem_rdata),
        .mem_to_reg(mem_wb_mem_to_reg),
        .wb_data(wb_data)
    );
endmodule


