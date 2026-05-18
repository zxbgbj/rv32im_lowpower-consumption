// Module: branch_predictor.
// Role: 2-bit BHT predictor queried in IF stage.
// Key ports: pc [31:0], predict_taken, update_valid, update_pc [31:0], update_taken.
// Connections: input from pc_manager/front_end, output to IF next-PC selection, update from resolved branches in EX.
module branch_predictor #(
    parameter ENTRIES = 1024,
    parameter HISTORY_BITS = 8
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc,
    output wire        predict_taken,
    output wire [HISTORY_BITS-1:0] query_history,
    input  wire        update_valid,
    input  wire [31:0] update_pc,
    input  wire [HISTORY_BITS-1:0] update_history,
    input  wire        update_taken
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

    localparam INDEX_W = clog2(ENTRIES);
    localparam EFFECTIVE_HISTORY_BITS = (HISTORY_BITS < INDEX_W) ? HISTORY_BITS : INDEX_W;
    reg [1:0] bht_table [0:ENTRIES-1];
    reg [HISTORY_BITS-1:0] ghr;
    integer i;

    wire [INDEX_W-1:0] history_mask = {{(INDEX_W-EFFECTIVE_HISTORY_BITS){1'b0}}, ghr[EFFECTIVE_HISTORY_BITS-1:0]};
    wire [INDEX_W-1:0] update_history_mask = {{(INDEX_W-EFFECTIVE_HISTORY_BITS){1'b0}}, update_history[EFFECTIVE_HISTORY_BITS-1:0]};
    wire [INDEX_W-1:0] index = pc[INDEX_W+1:2] ^ history_mask;
    wire [INDEX_W-1:0] update_index = update_pc[INDEX_W+1:2] ^ update_history_mask;

    assign predict_taken = rst ? 1'b0 : bht_table[index][1];
    assign query_history = ghr;

    initial begin
        ghr = {HISTORY_BITS{1'b0}};
        for (i = 0; i < ENTRIES; i = i + 1) begin
            // A weakly-taken reset bias is friendlier to loop-heavy code such as CoreMark.
            bht_table[i] = 2'b10;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            ghr <= {HISTORY_BITS{1'b0}};
        end else if (update_valid) begin
            case ({update_taken, bht_table[update_index]})
                3'b0_00: bht_table[update_index] <= 2'b00;
                3'b0_01: bht_table[update_index] <= 2'b00;
                3'b0_10: bht_table[update_index] <= 2'b01;
                3'b0_11: bht_table[update_index] <= 2'b10;
                3'b1_00: bht_table[update_index] <= 2'b01;
                3'b1_01: bht_table[update_index] <= 2'b10;
                3'b1_10: bht_table[update_index] <= 2'b11;
                3'b1_11: bht_table[update_index] <= 2'b11;
                default: bht_table[update_index] <= 2'b01;
            endcase
            ghr <= {ghr[HISTORY_BITS-2:0], update_taken};
        end
    end
endmodule
