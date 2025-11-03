module pipeline_regs (
    input  CLK,
    input  RST,

    // IF -> ID
    input  [31:0] PC_IF,
    input  [31:0] IDATA_IF,
    input  [31:0] PC4_IF,
    output reg [31:0] PC_FD,
    output reg [31:0] IDATA_FD,
    output reg [31:0] PC4_FD,

    // ID stage values to latch
    // // control
    input  [4:0]  ALUOp_ID,
    input         ALUSrc_ID,
    input  [2:0]  FT_ID,
    input  [1:0]  MemtoReg_ID,
    input         RegWrite_ID,
    input         Branch_ID,
    input         MemWrite_ID,
    input  [1:0]  MemRead_ID,
    input         RegDst_ID,
    input         ALUorSHIFT_ID,
    input         DMSE_ID,
    // // data
    input  [31:0] RF_DATA1,
    input  [31:0] RF_DATA2,
    input  [4:0]  RD_ID,
    input  [4:0]  RT_ID,
    input  [31:0] IMM_VAL_EXT_ID,
    input         RS1_PC_ID,
    input         RS1_Z_ID,

    // ID -> EX
    // // PC
    output reg [31:0] PC_DE,
    output reg [31:0] PC4_DE,
    // // control
    output reg [1:0]  MemtoReg_DE,
    output reg        RegWrite_DE,
    output reg        Branch_DE,
    output reg        MemWrite_DE,
    output reg [1:0]  MemRead_DE,
    output reg        ALUSrc_DE,
    output reg [4:0]  ALUOp_DE,
    output reg        RegDst_DE,
    output reg        ALUorSHIFT_DE,
    output reg        DMSE_DE,
    output reg [2:0]  FT_DE,
    // // data
    output reg [31:0] RF_DATA1_DE,
    output reg [31:0] RF_DATA2_DE,
    output reg [31:0] IMM_VAL_EXT_DE,
    output reg [4:0]  RD_DE,
    output reg [4:0]  RT_DE,
    output reg        RS1_PC_DE,
    output reg        RS1_Z_DE,

    // EX stage values to latch into EX/MEM
    input  [31:0] ALU_VAL_E,
    input  [31:0] STORE_VAL_E,

    // EX -> MEM
    // // PC
    output reg [31:0] PC4_EM,
    // // control
    output reg [1:0]  MemtoReg_EM,
    output reg        RegWrite_EM,
    output reg        MemWrite_EM,
    output reg [1:0]  MemRead_EM,
    output reg        RegDst_EM,
    output reg        DMSE_EM,
    // // data
    output reg [31:0] ALU_VAL_EM,
    output reg [31:0] STORE_VAL_EM,
    output reg [4:0]  RD_EM,
    output reg [4:0]  RT_EM,


    // MEM -> WB
    output reg [31:0] PC4_MW,
    output reg [31:0] ALU_VAL_MW,
    output reg [4:0]  RD_MW,
    output reg [4:0]  RT_MW,
    output reg [1:0]  MemtoReg_MW,
    output reg        RegWrite_MW,
    output reg        RegDst_MW
);
    // IF/ID
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            PC_FD    <= 32'h0000_0000;
            PC4_FD   <= 32'h0000_0004;
            IDATA_FD <= 32'h0000_0000;
        end else begin
            PC_FD    <= PC_IF;
            PC4_FD   <= PC4_IF;
            IDATA_FD <= IDATA_IF;
        end
    end

    // ID/EX
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            PC_DE        <= 32'h0000_0000;
            PC4_DE       <= 32'h0000_0000;
            RF_DATA1_DE  <= 32'h0000_0000;
            RF_DATA2_DE  <= 32'h0000_0000;
            ALUOp_DE     <= 5'b00000;
            RD_DE        <= 5'b00000;
            RT_DE        <= 5'b00000;
            MemtoReg_DE  <= 2'b00;
            RegWrite_DE  <= 1'b0;
            RegDst_DE    <= 1'b0;
            ALUSrc_DE    <= 1'b0;
            FT_DE        <= 3'b000;
            RS1_PC_DE    <= 1'b0;
            RS1_Z_DE     <= 1'b0;
            IMM_VAL_EXT_DE <= 32'h0000_0000;
            // 追加: 未初期化の制御線
            Branch_DE    <= 1'b0;
            MemWrite_DE  <= 1'b0;
            MemRead_DE   <= 2'b00;
            ALUorSHIFT_DE<= 1'b0;
            DMSE_DE      <= 1'b0;
        end else begin
            PC_DE        <= PC_FD;
            PC4_DE       <= PC4_FD;
            RF_DATA1_DE  <= RF_DATA1;
            RF_DATA2_DE  <= RF_DATA2;
            ALUOp_DE     <= ALUOp_ID;
            RD_DE        <= RD_ID;
            RT_DE        <= RT_ID;
            IMM_VAL_EXT_DE <= IMM_VAL_EXT_ID;
            ALUSrc_DE    <= ALUSrc_ID;
            FT_DE        <= FT_ID;
            RS1_PC_DE    <= RS1_PC_ID;
            RS1_Z_DE     <= RS1_Z_ID;
            MemtoReg_DE  <= MemtoReg_ID;
            RegWrite_DE  <= RegWrite_ID;
            RegDst_DE    <= RegDst_ID;
            // 追加: 未代入の制御線
            Branch_DE    <= Branch_ID;
            MemWrite_DE  <= MemWrite_ID;
            MemRead_DE   <= MemRead_ID;
            ALUorSHIFT_DE<= ALUorSHIFT_ID;
            DMSE_DE      <= DMSE_ID;
        end
    end

    // EX/MEM
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            PC4_EM       <= 32'h0000_0000;
            ALU_VAL_EM   <= 32'h0000_0000;
            STORE_VAL_EM <= 32'h0000_0000;
            RD_EM        <= 5'b00000;
            RT_EM        <= 5'b00000;
            MemtoReg_EM  <= 2'b00;
            RegWrite_EM  <= 1'b0;
            RegDst_EM    <= 1'b0;
            // 追加
            MemWrite_EM  <= 1'b0;
            MemRead_EM   <= 2'b00;
            DMSE_EM      <= 1'b0;
        end else begin
            PC4_EM       <= PC4_DE;
            ALU_VAL_EM   <= ALU_VAL_E;
            STORE_VAL_EM <= STORE_VAL_E;
            RD_EM        <= RD_DE;
            RT_EM        <= RT_DE;
            MemtoReg_EM  <= MemtoReg_DE;
            RegWrite_EM  <= RegWrite_DE;
            RegDst_EM    <= RegDst_DE;
            // 追加
            MemWrite_EM  <= MemWrite_DE;
            MemRead_EM   <= MemRead_DE;
            DMSE_EM      <= DMSE_DE;
        end
    end

    // MEM/WB
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            PC4_MW      <= 32'h0000_0000;
            ALU_VAL_MW  <= 32'h0000_0000;
            RD_MW       <= 5'b00000;
            RT_MW       <= 5'b00000;
            MemtoReg_MW <= 2'b00;
            RegWrite_MW <= 1'b0;
            RegDst_MW   <= 1'b0;
        end else begin
            PC4_MW      <= PC4_EM;
            ALU_VAL_MW  <= ALU_VAL_EM;
            RD_MW       <= RD_EM;
            RT_MW       <= RT_EM;
            MemtoReg_MW <= MemtoReg_EM;
            RegWrite_MW <= RegWrite_EM;
            RegDst_MW   <= RegDst_EM;
        end
    end

endmodule