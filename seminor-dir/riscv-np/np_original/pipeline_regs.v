module pipeline_regs (
    input  wire       CLK, input wire RST,

    // flush / stall
    input  wire       flush_FD,
    input  wire       flush_DE,
    input  wire       stall_FD,
    input  wire       stall_DE,

    // IF/ID in
    input  wire [31:0] PC_IF, 
    input  wire [31:0] IDATA_IF, 
    input  wire [31:0] PC4_IF,
    // IF/ID out
    output reg  [31:0] PC_FD, 
    output reg  [31:0] IDATA_FD, 
    output reg  [31:0] PC4_FD,

    // ID->EX in
    input  wire [31:0] RF_DATA1, 
    input  wire [31:0] RF_DATA2,
    input  wire [4:0]  ALUOp_ID,
    input  wire [4:0]  RD_ID,
    input  wire [4:0]  RS1_ID,
    input  wire [4:0]  RS2_ID,
    input  wire [31:0] IMM_VAL_EXT_ID,
    input  wire        ALUSrc_ID,
    input  wire [2:0]  FT_ID,
    input  wire        RS1_PC_ID, 
    input  wire        RS1_Z_ID,
    input  wire [1:0]  MemtoReg_ID,
    input  wire        RegWrite_ID,
    input  wire        Branch_ID,
    input  wire [1:0]  MemWrite_ID,
    input  wire [1:0]  MemRead_ID,
    input  wire        ALUorSHIFT_ID,
    input  wire        DMSE_ID,
    input  wire [1:0]  PACK_SIZE_ID,

    // ID/EX out
    output reg  [31:0] PC_DE, 
    output reg  [31:0] PC4_DE,
    output reg  [31:0] RF_DATA1_DE, 
    output reg  [31:0] RF_DATA2_DE,
    output reg  [4:0]  ALUOp_DE,
    output reg  [31:0] IMM_VAL_EXT_DE,
    output reg  [4:0]  RD_DE,
    output reg  [4:0]  RS1_DE,
    output reg  [4:0]  RS2_DE,
    output reg         RS1_PC_DE, 
    output reg         RS1_Z_DE,
    output reg  [1:0]  MemtoReg_DE,
    output reg         RegWrite_DE,
    output reg         ALUSrc_DE,
    output reg  [2:0]  FT_DE,
    output reg         Branch_DE,
    output reg  [1:0]  MemWrite_DE,
    output reg  [1:0]  MemRead_DE,
    output reg         ALUorSHIFT_DE,
    output reg         DMSE_DE,
    output reg  [1:0]  PACK_SIZE_DE,

    // EX->MEM in
    input  wire [31:0] ALU_VAL_E, 
    input  wire [31:0] STORE_VAL_E,

    // EX/MEM out
    output reg  [31:0] PC4_EM, 
    output reg  [31:0] ALU_VAL_EM, 
    output reg  [31:0] STORE_VAL_EM,
    output reg  [4:0]  RD_EM,
    output reg  [1:0]  MemtoReg_EM,
    output reg         RegWrite_EM,
    output reg  [1:0]  MemWrite_EM,
    output reg  [1:0]  MemRead_EM,
    output reg         DMSE_EM,

    // MEM/WB out
    output reg  [31:0] PC4_MW, 
    output reg  [31:0] ALU_VAL_MW,
    output reg  [4:0]  RD_MW,
    output reg  [1:0]  MemtoReg_MW,
    output reg         RegWrite_MW
);
    // IF/ID
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            PC_FD    <= 32'h0000_0000;
            PC4_FD   <= 32'h0000_0000;
            IDATA_FD <= 32'h0000_0000;
        end else if (flush_FD) begin
            PC_FD    <= 32'h0000_0000;
            PC4_FD   <= 32'h0000_0000;
            IDATA_FD <= 32'h0000_0000; // NOP
        end else if (!stall_FD) begin
            PC_FD    <= PC_IF;
            PC4_FD   <= PC4_IF;
            IDATA_FD <= IDATA_IF;
        end
        // stall_FD のときは保持
    end

    // ID/EX
    always @(posedge CLK or posedge RST) begin
        if (RST || flush_DE) begin
            PC_DE<=0; PC4_DE<=0; RF_DATA1_DE<=0; RF_DATA2_DE<=0;
            ALUOp_DE<=0; IMM_VAL_EXT_DE<=0; RD_DE<=0; RS1_DE<=0; RS2_DE<=0;
            RS1_PC_DE<=0; RS1_Z_DE<=0;
            MemtoReg_DE<=0; RegWrite_DE<=0; ALUSrc_DE<=0; FT_DE<=0; Branch_DE<=0;
            MemWrite_DE<=0; MemRead_DE<=0; ALUorSHIFT_DE<=0; DMSE_DE<=0; PACK_SIZE_DE<=0;
        end else if (!stall_DE) begin
            PC_DE<=PC_FD; PC4_DE<=PC4_FD; RF_DATA1_DE<=RF_DATA1; RF_DATA2_DE<=RF_DATA2;
            ALUOp_DE<=ALUOp_ID; IMM_VAL_EXT_DE<=IMM_VAL_EXT_ID; RD_DE<=RD_ID; RS1_DE<=RS1_ID; RS2_DE<=RS2_ID;
            RS1_PC_DE<=RS1_PC_ID; RS1_Z_DE<=RS1_Z_ID;
            MemtoReg_DE<=MemtoReg_ID; RegWrite_DE<=RegWrite_ID; ALUSrc_DE<=ALUSrc_ID; FT_DE<=FT_ID; Branch_DE<=Branch_ID;
            MemWrite_DE<=MemWrite_ID; MemRead_DE<=MemRead_ID; ALUorSHIFT_DE<=ALUorSHIFT_ID; DMSE_DE<=DMSE_ID; PACK_SIZE_DE<=PACK_SIZE_ID;
        end
        // stall_DE のときは保持
    end

    // EX/MEM
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            PC4_EM<=0; ALU_VAL_EM<=0; STORE_VAL_EM<=0; RD_EM<=0;
            MemtoReg_EM<=0; RegWrite_EM<=0;
            MemWrite_EM<=0; MemRead_EM<=0; DMSE_EM<=0;
        end else begin
            PC4_EM<=PC4_DE; ALU_VAL_EM<=ALU_VAL_E; STORE_VAL_EM<=STORE_VAL_E; RD_EM<=RD_DE;
            MemtoReg_EM<=MemtoReg_DE; RegWrite_EM<=RegWrite_DE;
            MemWrite_EM<=MemWrite_DE; MemRead_EM<=MemRead_DE; DMSE_EM<=DMSE_DE;
        end
    end

    // MEM/WB
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            PC4_MW<=0; ALU_VAL_MW<=0; RD_MW<=0; MemtoReg_MW<=0; RegWrite_MW<=0;
        end else begin
            PC4_MW<=PC4_EM; ALU_VAL_MW<=ALU_VAL_EM; RD_MW<=RD_EM; MemtoReg_MW<=MemtoReg_EM; RegWrite_MW<=RegWrite_EM;
        end
    end
endmodule