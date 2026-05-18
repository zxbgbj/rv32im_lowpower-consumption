// Module: dmem_bram.
// Role: synchronous data memory model with byte write enables and low-power enable gating.
// Key ports: addr [31:0], wdata [31:0], we [3:0], en, rdata [31:0].
// Connections: accessed from MEM stage and from top-level ISA/test flows through cpu_top.
module dmem_bram #(
    parameter MEM_FILE = "",
    parameter DEPTH_WORDS = 256
) (
    input  wire        clk,
    input  wire        en,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  we,
    output reg  [31:0] rdata
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
    wire [ADDR_W-1:0] word_idx = addr[ADDR_W+1:2];

    initial begin
        for (i = 0; i < DEPTH_WORDS; i = i + 1) begin
            mem[i] = 32'd0;
        end
        if (MEM_FILE != "") begin
            $readmemh(MEM_FILE, mem);
        end
        rdata = 32'd0;
    end

    always @(posedge clk) begin
        if (en) begin
            rdata <= mem[word_idx];
            if (we[0]) mem[word_idx][7:0]   <= wdata[7:0];
            if (we[1]) mem[word_idx][15:8]  <= wdata[15:8];
            if (we[2]) mem[word_idx][23:16] <= wdata[23:16];
            if (we[3]) mem[word_idx][31:24] <= wdata[31:24];
        end
    end
endmodule
