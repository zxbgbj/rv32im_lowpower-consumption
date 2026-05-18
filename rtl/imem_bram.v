`include "memory_profile.vh"

// Module: imem_bram.
// Role: synchronous instruction memory model with low-power enable gating.
// Key ports: addr [31:0], en, rdata [31:0], secondary debug port addr_b [31:0], en_b, rdata_b [31:0].
// Connections: primary port serves the front_end fetch path and the optional secondary port supports inspection flows.
module imem_bram #(
    parameter MEM_FILE = "mem/program.hex",
    parameter DEPTH_WORDS = `RV32IM_IMEM_DEPTH_WORDS
) (
    input  wire        clk,
    input  wire        en,
    input  wire [31:0] addr,
    output reg  [31:0] rdata,
    input  wire        en_b,
    input  wire [3:0]  we_b,
    input  wire [31:0] addr_b,
    input  wire [31:0] wdata_b,
    output reg  [31:0] rdata_b
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

    localparam ADDR_W = clog2(DEPTH_WORDS);
    (* ram_style = "block" *) reg [31:0] mem [0:DEPTH_WORDS-1];
    integer i;
    wire [ADDR_W-1:0] word_idx_a = addr[ADDR_W+1:2];
    wire [ADDR_W-1:0] word_idx_b = addr_b[ADDR_W+1:2];

    initial begin
        for (i = 0; i < DEPTH_WORDS; i = i + 1) begin
            mem[i] = 32'h0000_0013;
        end
        if (MEM_FILE != "") begin
            $readmemh(MEM_FILE, mem);
        end
        rdata = 32'h0000_0013;
        rdata_b = 32'h0000_0013;
    end

    always @(posedge clk) begin
        if (en) begin
            rdata <= mem[word_idx_a];
        end
        if (en_b) begin
            rdata_b <= mem[word_idx_b];
            if (we_b[0]) mem[word_idx_b][7:0] <= wdata_b[7:0];
            if (we_b[1]) mem[word_idx_b][15:8] <= wdata_b[15:8];
            if (we_b[2]) mem[word_idx_b][23:16] <= wdata_b[23:16];
            if (we_b[3]) mem[word_idx_b][31:24] <= wdata_b[31:24];
        end
    end
endmodule
