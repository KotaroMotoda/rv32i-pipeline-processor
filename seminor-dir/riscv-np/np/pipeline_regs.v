module pipeline_regs (
    // IF/ID pipeline registers
    input wire CLK,
    input wire RST,
    input wire [31:0] PC_IF,
    input wire [31:0] PC4_IF,
    input wire [31:0] IDATA_IF,
    output reg [31:0] PC_FD,
    output reg [31:0] PC4_FD,
    output reg [31:0] IDATA_FD,

    // ID/EX pipeline registers
    input wire [31:0] PC_DE,
    input wire [31:0] RF_DATA1_DE,
    input wire [31:0] RF_DATA2_DE,
    input wire [4:0] IALU_DE,
    input wire [31:0] IMM_VAL_DE,
    input wire [4:0] RD_DE,
    output reg [31:0] PC4_DE,
    output reg [31:0] PC_DE_OUT,
    output reg [31:0] RF_DATA1_DE_OUT,
    output reg [31:0] RF_DATA2_DE_OUT,
    output reg [4:0] IALU_DE_OUT,
    output reg [31:0] IMM_VAL_DE_OUT,
    output reg [4:0] RD_DE_OUT,

    // EX/MEM pipeline registers
    input wire [31:0] PC4_EM,
    input wire [31:0] RD_VAL_E,
    input wire [4:0] RD_EM,
    output reg [31:0] PC4_EM_OUT,
    output reg [31:0] RD_VAL_EM_OUT,
    output reg [4:0] RD_EM_OUT,

    // MEM/WB pipeline registers
    input wire [31:0] PC4_MW,
    input wire [31:0] MEM_DATA_MW,
    input wire [4:0] RD_MW,
    output reg [31:0] PC4_MW_OUT,
    output reg [31:0] MEM_DATA_MW_OUT,
    output reg [4:0] RD_MW_OUT
);

// IF/ID pipeline register update
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        PC_FD <= 32'h00000000;
        PC4_FD <= 32'h00000000;
        IDATA_FD <= 32'h00000000;
    end else begin
        PC_FD <= PC_IF;
        PC4_FD <= PC4_IF;
        IDATA_FD <= IDATA_IF;
    end
end

// ID/EX pipeline register update
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        PC_DE_OUT <= 32'h00000000;
        PC4_DE <= 32'h00000000;
        RF_DATA1_DE_OUT <= 32'h00000000;
        RF_DATA2_DE_OUT <= 32'h00000000;
        IALU_DE_OUT <= 5'b00000;
        IMM_VAL_DE_OUT <= 32'h00000000;
        RD_DE_OUT <= 5'b00000;
    end else begin
        PC_DE_OUT <= PC_DE;
        PC4_DE <= PC4_DE;
        RF_DATA1_DE_OUT <= RF_DATA1_DE;
        RF_DATA2_DE_OUT <= RF_DATA2_DE;
        IALU_DE_OUT <= IALU_DE;
        IMM_VAL_DE_OUT <= IMM_VAL_DE;
        RD_DE_OUT <= RD_DE;
    end
end

// EX/MEM pipeline register update
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        PC4_EM_OUT <= 32'h00000000;
        RD_VAL_EM_OUT <= 32'h00000000;
        RD_EM_OUT <= 5'b00000;
    end else begin
        PC4_EM_OUT <= PC4_EM;
        RD_VAL_EM_OUT <= RD_VAL_E;
        RD_EM_OUT <= RD_EM;
    end
end

// MEM/WB pipeline register update
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        PC4_MW_OUT <= 32'h00000000;
        MEM_DATA_MW_OUT <= 32'h00000000;
        RD_MW_OUT <= 5'b00000;
    end else begin
        PC4_MW_OUT <= PC4_MW;
        MEM_DATA_MW_OUT <= MEM_DATA_MW;
        RD_MW_OUT <= RD_MW;
    end
end

endmodule