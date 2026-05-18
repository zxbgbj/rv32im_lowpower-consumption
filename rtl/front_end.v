// Module: front_end.
// Role: IF-stage front end containing PC management, predictor query, BTB query, and instruction memory access.
// Key ports: redirect_valid, redirect_pc [31:0], stall, imem_en, fetch_valid, fetch_pc [31:0], instr32 [31:0].
// Connections: output feeds IF/ID register, predictor outputs feed the next-PC path, and EX redirect updates the front end.
module front_end #(
    parameter IMEM_FILE = "mem/program.hex",
    parameter BHT_ENTRIES = 1024,
    parameter BTB_ENTRIES = 256,
    parameter RAS_DEPTH = 16,
    parameter HISTORY_BITS = 8
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,
    input  wire        redirect_valid,
    input  wire [31:0] redirect_pc,
    input  wire        pred_update_valid,
    input  wire [31:0] pred_update_pc,
    input  wire        pred_update_taken,
    input  wire [31:0] pred_update_target,
    input  wire        pred_update_is_uncond,
    input  wire        pred_update_is_call,
    input  wire        pred_update_is_return,
    input  wire [31:0] pred_update_return_addr,
    input  wire [HISTORY_BITS-1:0] pred_update_history,
    input  wire        imem_write_en,
    input  wire [3:0]  imem_write_we,
    input  wire [31:0] imem_write_addr,
    input  wire [31:0] imem_write_data,
    output wire [31:0] fetch_pc,
    output wire [31:0] instr32,
    output wire        instr_is_compressed,
    output wire [1:0]  instr_len,
    output wire        predict_taken,
    output wire [31:0] predict_target,
    output wire [HISTORY_BITS-1:0] predict_history,
    output wire        fetch_valid,
    output wire [31:0] imem_addr_debug,
    output wire        imem_en
);
    function integer clog2;
        input integer value;
        integer tmp;
        begin
            tmp = value - 1;
            clog2 = 0;
            while (tmp > 0) begin
                tmp = tmp >> 1;
                clog2 = clog2 + 1;
            end
        end
    endfunction

    localparam RAS_PTR_W = clog2(RAS_DEPTH + 1);

    reg  [31:0] pc_req;
    reg  [31:0] fetch_pc_r;
    reg         fetch_valid_r;
    reg         predict_taken_r;
    reg  [31:0] predict_target_r;
    reg  [HISTORY_BITS-1:0] predict_history_r;
    reg  [31:0] ras_stack [0:RAS_DEPTH-1];
    reg  [RAS_PTR_W-1:0] ras_count;
    wire [31:0] imem_rdata;
    wire        bht_taken;
    wire        btb_hit;
    wire        btb_is_uncond;
    wire        btb_is_return;
    wire [31:0] btb_target;
    wire        pred_taken_int;
    wire        ras_valid;
    wire [31:0] ras_top;
    wire [31:0] pred_target_int;
    wire [31:0] next_pc;
    wire        bht_update_valid;
    wire [HISTORY_BITS-1:0] bht_history_snapshot;

    assign fetch_pc = fetch_pc_r;
    assign instr32 = imem_rdata;
    assign instr_is_compressed = 1'b0;
    assign instr_len = 2'd2;
    assign pred_taken_int = btb_hit && (btb_is_uncond || bht_taken);
    assign ras_valid = (ras_count != 0);
    assign ras_top = ras_valid ? ras_stack[ras_count-1] : 32'd0;
    assign pred_target_int = (btb_is_return && ras_valid) ? ras_top : btb_target;
    // Train the conditional-direction predictor only with real conditional
    // branches. Unconditional jumps/calls/returns still update BTB/RAS, but
    // should not pollute the BHT used for taken/not-taken decisions.
    assign bht_update_valid = pred_update_valid && !pred_update_is_uncond;
    assign predict_taken = predict_taken_r;
    assign predict_target = predict_target_r;
    assign predict_history = predict_history_r;
    assign fetch_valid = fetch_valid_r;
    assign imem_addr_debug = pc_req;
    assign imem_en = rst || redirect_valid || !stall;

    imem_bram #(.MEM_FILE(IMEM_FILE)) imem_bram_u (
        .clk(clk),
        .en(imem_en),
        .addr(pc_req),
        .rdata(imem_rdata),
        .en_b(imem_write_en),
        .we_b(imem_write_we),
        .addr_b(imem_write_addr),
        .wdata_b(imem_write_data),
        .rdata_b()
    );

    branch_predictor #(
        .ENTRIES(BHT_ENTRIES),
        .HISTORY_BITS(HISTORY_BITS)
    ) branch_predictor_u (
        .clk(clk),
        .rst(rst),
        .pc(pc_req),
        .predict_taken(bht_taken),
        .query_history(bht_history_snapshot),
        .update_valid(bht_update_valid),
        .update_pc(pred_update_pc),
        .update_history(pred_update_history),
        .update_taken(pred_update_taken)
    );

    btb #(.ENTRIES(BTB_ENTRIES)) btb_u (
        .clk(clk),
        .rst(rst),
        .pc(pc_req),
        .hit(btb_hit),
        .target(btb_target),
        .is_uncond(btb_is_uncond),
        .is_return(btb_is_return),
        .update_valid(pred_update_valid),
        .update_pc(pred_update_pc),
        .update_target(pred_update_target),
        .update_taken(pred_update_taken),
        .update_is_uncond(pred_update_is_uncond),
        .update_is_return(pred_update_is_return)
    );

    pc_manager pc_manager_u (
        .current_pc(pc_req),
        .seq_pc(pc_req + 32'd4),
        .predict_taken(pred_taken_int),
        .predict_target(pred_target_int),
        .redirect_valid(redirect_valid),
        .redirect_pc(redirect_pc),
        .next_pc(next_pc)
    );

    always @(posedge clk) begin
        if (rst) begin
            pc_req <= 32'd0;
            fetch_pc_r <= 32'd0;
            fetch_valid_r <= 1'b0;
            predict_taken_r <= 1'b0;
            predict_target_r <= 32'd0;
            predict_history_r <= {HISTORY_BITS{1'b0}};
            ras_count <= {RAS_PTR_W{1'b0}};
        end else begin
            if (pred_update_valid) begin
                if (pred_update_is_return && !pred_update_is_call) begin
                    if (ras_count != 0) begin
                        ras_count <= ras_count - 1'b1;
                    end
                end else if (pred_update_is_call && !pred_update_is_return) begin
                    if (ras_count < RAS_DEPTH) begin
                        ras_stack[ras_count] <= pred_update_return_addr;
                        ras_count <= ras_count + 1'b1;
                    end else begin
                        ras_stack[RAS_DEPTH-1] <= pred_update_return_addr;
                    end
                end else if (pred_update_is_call && pred_update_is_return) begin
                    if (ras_count != 0) begin
                        ras_stack[ras_count-1] <= pred_update_return_addr;
                    end else begin
                        ras_stack[0] <= pred_update_return_addr;
                        ras_count <= {{(RAS_PTR_W-1){1'b0}}, 1'b1};
                    end
                end
            end
            if (redirect_valid) begin
                pc_req <= redirect_pc;
                fetch_valid_r <= 1'b0;
                predict_taken_r <= 1'b0;
                predict_target_r <= 32'd0;
                predict_history_r <= {HISTORY_BITS{1'b0}};
            end else if (!stall) begin
                // Update fetch metadata only when a real IMEM access is issued.
                // During stall, IMEM is disabled and instr32 holds its previous word,
                // so fetch_pc must also hold its previous value to stay aligned.
                fetch_pc_r <= pc_req;
                predict_taken_r <= pred_taken_int;
                predict_target_r <= pred_target_int;
                predict_history_r <= bht_history_snapshot;
                pc_req <= next_pc;
                fetch_valid_r <= 1'b1;
            end
        end
    end
endmodule
