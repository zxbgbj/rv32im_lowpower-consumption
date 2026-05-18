// Module: csr_file.
// Role: minimal machine-mode CSR block for trap entry and mret return.
// Key ports: csr_addr [11:0], csr_cmd [2:0], wdata [31:0], rdata [31:0], trap inputs, trap_pc [31:0].
// Connections: accessed from EX/system path and returns state to cpu_top redirect and write-back logic.
module csr_file (
    input  wire        clk,
    input  wire        rst,
    input  wire [11:0] read_addr,
    output reg  [31:0] read_data,
    input  wire        write_en,
    input  wire [11:0] write_addr,
    input  wire [31:0] write_data,
    input  wire        trap_enter,
    input  wire [31:0] trap_pc,
    input  wire [31:0] trap_cause,
    output wire [31:0] mtvec,
    output wire [31:0] mepc,
    output wire [31:0] mcause,
    output wire [31:0] mstatus
);
    localparam CSR_MSTATUS = 12'h300;
    localparam CSR_MTVEC   = 12'h305;
    localparam CSR_MSCRATCH= 12'h340;
    localparam CSR_MEPC    = 12'h341;
    localparam CSR_MCAUSE  = 12'h342;
    localparam CSR_MCYCLE  = 12'hB00;
    localparam CSR_MCYCLEH = 12'hB80;
    localparam CSR_CYCLE   = 12'hC00;
    localparam CSR_CYCLEH  = 12'hC80;

    reg [31:0] csr_mstatus;
    reg [31:0] csr_mtvec;
    reg [31:0] csr_mscratch;
    reg [31:0] csr_mepc;
    reg [31:0] csr_mcause;
    reg [63:0] csr_mcycle;
    reg [63:0] csr_mcycle_next;

    assign mstatus = csr_mstatus;
    assign mtvec   = csr_mtvec;
    assign mepc    = csr_mepc;
    assign mcause  = csr_mcause;

    always @(*) begin
        case (read_addr)
            CSR_MSTATUS: read_data = csr_mstatus;
            CSR_MTVEC:   read_data = csr_mtvec;
            CSR_MSCRATCH:read_data = csr_mscratch;
            CSR_MEPC:    read_data = csr_mepc;
            CSR_MCAUSE:  read_data = csr_mcause;
            CSR_MCYCLE,
            CSR_CYCLE:   read_data = csr_mcycle[31:0];
            CSR_MCYCLEH,
            CSR_CYCLEH:  read_data = csr_mcycle[63:32];
            default:     read_data = 32'd0;
        endcase
    end

    always @(*) begin
        csr_mcycle_next = csr_mcycle + 64'd1;

        if (write_en) begin
            case (write_addr)
                CSR_MCYCLE:  csr_mcycle_next[31:0]  = write_data;
                CSR_MCYCLEH: csr_mcycle_next[63:32] = write_data;
                default: begin
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            csr_mstatus <= 32'd0;
            csr_mtvec   <= 32'h0000_0100;
            csr_mscratch<= 32'd0;
            csr_mepc    <= 32'd0;
            csr_mcause  <= 32'd0;
            csr_mcycle  <= 64'd0;
        end else begin
            if (trap_enter) begin
                csr_mepc   <= trap_pc;
                csr_mcause <= trap_cause;
            end

            csr_mcycle <= csr_mcycle_next;

            if (write_en) begin
                case (write_addr)
                    CSR_MSTATUS: csr_mstatus <= write_data;
                    CSR_MTVEC:   csr_mtvec   <= {write_data[31:2], 2'b00};
                    CSR_MSCRATCH:csr_mscratch<= write_data;
                    CSR_MEPC:    csr_mepc    <= {write_data[31:1], 1'b0};
                    CSR_MCAUSE:  csr_mcause  <= write_data;
                    default: begin
                    end
                endcase
            end
        end
    end
endmodule

