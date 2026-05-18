// Module: regfile.
// Role: integer register file for x0-x31 with one write port and two read ports.
// Key ports: rs1_addr [4:0], rs2_addr [4:0], rd_addr [4:0], rd_wdata [31:0], rd_we, rs1_rdata [31:0], rs2_rdata [31:0].
// Connections: read in ID stage and written from WB stage.
module regfile (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    input  wire        we,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data
);
    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'd0;
            end
        end else if (we && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_data;
        end
    end

    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 :
                      ((we && (rd_addr == rs1_addr) && (rd_addr != 5'd0)) ? rd_data : regs[rs1_addr]);
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 :
                      ((we && (rd_addr == rs2_addr) && (rd_addr != 5'd0)) ? rd_data : regs[rs2_addr]);
endmodule

