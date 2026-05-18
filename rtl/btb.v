// Module: btb.
// Role: direct-mapped branch target buffer used in IF stage.
// Key ports: pc [31:0], hit, target [31:0], update_valid, update_pc [31:0], update_target [31:0].
// Connections: queried by front_end and updated after EX resolves a taken branch or jump.
module btb #(
    parameter ENTRIES = 256
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc,
    output wire        hit,
    output wire [31:0] target,
    output wire        is_uncond,
    output wire        is_return,
    input  wire        update_valid,
    input  wire [31:0] update_pc,
    input  wire [31:0] update_target,
    input  wire        update_taken,
    input  wire        update_is_uncond,
    input  wire        update_is_return
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
    reg        valid [0:ENTRIES-1];
    reg        uncond [0:ENTRIES-1];
    reg        ret [0:ENTRIES-1];
    reg [31-INDEX_W-2:0] tags [0:ENTRIES-1];
    reg [31:0] target_mem [0:ENTRIES-1];
    integer i;

    wire [INDEX_W-1:0] index = pc[INDEX_W+1:2];
    wire [31-INDEX_W-2:0] tag = pc[31:INDEX_W+2];
    wire [INDEX_W-1:0] update_index = update_pc[INDEX_W+1:2];
    wire [31-INDEX_W-2:0] update_tag = update_pc[31:INDEX_W+2];

    assign hit = !rst && valid[index] && (tags[index] == tag);
    assign target = hit ? target_mem[index] : 32'd0;
    assign is_uncond = hit ? uncond[index] : 1'b0;
    assign is_return = hit ? ret[index] : 1'b0;

    initial begin
        for (i = 0; i < ENTRIES; i = i + 1) begin
            valid[i] = 1'b0;
            uncond[i] = 1'b0;
            ret[i] = 1'b0;
            tags[i] = {(31-INDEX_W-1){1'b0}};
            target_mem[i] = 32'd0;
        end
    end

    always @(posedge clk) begin
        if (update_valid && update_taken) begin
            valid[update_index] <= 1'b1;
            uncond[update_index] <= update_is_uncond;
            ret[update_index] <= update_is_return;
            tags[update_index] <= update_tag;
            target_mem[update_index] <= update_target;
        end
    end
endmodule
