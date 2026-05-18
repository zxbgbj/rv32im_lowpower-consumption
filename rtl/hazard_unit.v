// Module: hazard_unit.
// Role: hazard detector for load-use stalls, branch flush, and multicycle hold conditions.
// Key ports: decode-stage source registers [4:0], ID/EX load information, stall, flush.
// Connections: inputs come from IF/ID and ID/EX state, outputs freeze or clear the front of the pipeline.
module hazard_unit (
    input  wire       id_ex_mem_read,
    input  wire [4:0] id_ex_rd,
    input  wire       ex_mem_mem_read,
    input  wire [4:0] ex_mem_rd,
    input  wire [4:0] if_id_rs1,
    input  wire [4:0] if_id_rs2,
    input  wire       if_id_uses_rs1,
    input  wire       if_id_uses_rs2,
    output wire       stall
);
    wire id_ex_hazard = id_ex_mem_read &&
                        (id_ex_rd != 5'd0) &&
                        (((id_ex_rd == if_id_rs1) && if_id_uses_rs1) ||
                         ((id_ex_rd == if_id_rs2) && if_id_uses_rs2));

    assign stall = id_ex_hazard;
endmodule
