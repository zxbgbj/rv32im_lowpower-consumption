// Module: mem_stage.
// Role: MEM-stage load/store formatter with byte enables, alignment, and sign/zero extension.
// Key ports: addr [31:0], store_data [31:0], mem_size [1:0], load_unsigned, dmem_wdata [31:0], dmem_we [3:0], load_data [31:0].
// Connections: input from EX/MEM register, drives dmem_bram, and returns formatted load_data to MEM/WB.
module mem_stage (
    input  wire [31:0] alu_result,
    input  wire [31:0] store_data,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [1:0]  mem_size,
    input  wire        load_unsigned,
    input  wire [31:0] dmem_rdata,
    output wire [31:0] dmem_addr,
    output reg  [31:0] dmem_wdata,
    output reg  [3:0]  dmem_we,
    output reg  [31:0] load_data
);
    wire [1:0] byte_off = alu_result[1:0];
    wire [15:0] half_sel = byte_off[1] ? dmem_rdata[31:16] : dmem_rdata[15:0];
    wire [7:0]  byte_sel = (byte_off == 2'd0) ? dmem_rdata[7:0] :
                           (byte_off == 2'd1) ? dmem_rdata[15:8] :
                           (byte_off == 2'd2) ? dmem_rdata[23:16] : dmem_rdata[31:24];

    assign dmem_addr = alu_result;

    always @(*) begin
        dmem_wdata = store_data;
        dmem_we = 4'b0000;
        case (mem_size)
            2'd0: begin
                dmem_wdata = {4{store_data[7:0]}} << (8 * byte_off);
                dmem_we = mem_write ? (4'b0001 << byte_off) : 4'b0000;
            end
            2'd1: begin
                dmem_wdata = {2{store_data[15:0]}} << (16 * byte_off[1]);
                dmem_we = mem_write ? (byte_off[1] ? 4'b1100 : 4'b0011) : 4'b0000;
            end
            default: begin
                dmem_wdata = store_data;
                dmem_we = mem_write ? 4'b1111 : 4'b0000;
            end
        endcase

        case (mem_size)
            2'd0: load_data = load_unsigned ? {24'd0, byte_sel} : {{24{byte_sel[7]}}, byte_sel};
            2'd1: load_data = load_unsigned ? {16'd0, half_sel} : {{16{half_sel[15]}}, half_sel};
            default: load_data = dmem_rdata;
        endcase
    end
endmodule
