`include "riscv.vh"
`include "inst.vh"
`include "alu.vh"
`define LITTLE_ENDIAN

module riscv
    #(
        parameter IMEM_BASE = 32'h0000_0000,
        parameter IMEM_SIZE = 32768,
        parameter IMEM_FILE = "prog.mif",
        parameter DMEM_BASE = 32'h0010_0000,
        parameter DMEM_SIZE = 32768,
        parameter DMEM_FILE = "data.mif"
    )
    (
        input  CLK,
        input  RSTN
    );

    wire RST = ~RSTN;

    // IF stage I/F
    wire [31:0] PC_IF;
    wire [31:0] PC4_IF;
    wire [31:0] IDATA_IF;

    // IF/ID pipeline
    wire [31:0] PC_FD;
    wire [31:0] IDATA_FD;
    wire [31:0] PC4_FD;

    // IR (endian)
    wire [31:0] IR;
`ifdef BIG_ENDIAN
    assign IR = IDATA_FD;
`endif
`ifdef LITTLE_ENDIAN
    assign IR = {IDATA_FD[7:0], IDATA_FD[15:8], IDATA_FD[23:16], IDATA_FD[31:24]};
`endif

    // ID stage outputs
    wire [2:0]  FT_ID;
    wire [4:0]  ALUOp_ID;
    wire [1:0]  MemtoReg_ID;
    wire        RegWrite_ID;
    wire        ALUSrc_ID;
    wire        DMSE_ID;
    wire        RS1_PC_ID;
    wire        RS1_Z_ID;
    wire        Branch_ID;
    wire        ALUorSHIFT_ID;
    wire [1:0]  MemWrite_ID;
    wire [1:0]  MemRead_ID;
    wire [4:0]  RD_ID;
    wire [31:0] IMM_VAL_EXT_ID;

    // RF output
    wire [31:0] RF_DATA1;
    wire [31:0] RF_DATA2;

    // ID/EX pipeline
    wire [31:0] PC_DE;
    wire [31:0] PC4_DE;
    wire [31:0] RF_DATA1_DE;
    wire [31:0] RF_DATA2_DE;
    wire [4:0]  ALUOp_DE;
    wire [31:0] IMM_VAL_EXT_DE;
    wire [4:0]  RD_DE;
    wire [4:0]  RS1_DE;       // 追加
    wire [4:0]  RS2_DE;       // 追加
    wire        RS1_PC_DE;
    wire        RS1_Z_DE;
    wire [1:0]  MemtoReg_DE;
    wire        RegWrite_DE;
    wire        ALUSrc_DE;
    wire        Branch_DE;
    wire        ALUorSHIFT_DE;
    wire        DMSE_DE;
    wire [1:0]  MemRead_DE;
    wire [1:0]  MemWrite_DE;
    wire [2:0]  FT_DE;

    // EX stage
    wire [31:0] ALU_VAL_E;
    wire [31:0] STORE_VAL_E;
    wire        isBranch_E;
    wire [31:0] PC_IMM_E;

    // EX/MEM pipeline
    wire [31:0] PC4_EM;
    wire [31:0] ALU_VAL_EM;
    wire [31:0] STORE_VAL_EM;
    wire [4:0]  RD_EM;
    wire [1:0]  MemtoReg_EM;
    wire        RegWrite_EM;
    wire [1:0]  MemWrite_EM;
    wire [1:0]  MemRead_EM;
    wire        DMSE_EM;

    // MEM/WB pipeline
    wire [31:0] PC4_MW;
    wire [31:0] ALU_VAL_MW;
    wire [4:0]  RD_MW;
    wire [1:0]  MemtoReg_MW;
    wire        RegWrite_MW;
    wire        RegDst_MW;

    // MEM data path
    wire [31:0] MEM_DATA_M;  // MEM段出力（mem_stage）
    reg  [31:0] MEM_DATA_MW; // MEM/WB ラッチ

    // WB stage
    wire [31:0] RD_VAL_WB;

    // 追加: ストール線を先に明示宣言（暗黙宣言回避）
    wire stall_IF;
    wire stall_FD;
    wire stall_DE;

    // IF stage
    if_stage #(
        .IMEM_BASE(IMEM_BASE),
        .IMEM_SIZE(IMEM_SIZE),
        .IMEM_FILE(IMEM_FILE)
    ) if_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .isBranch_E(isBranch_E),
        .PC_IMM_E(PC_IMM_E),
        .stall_IF(stall_IF),
        .PC_IF(PC_IF),
        .PC4_IF(PC4_IF),
        .IDATA_IF(IDATA_IF)
    );

    // ID stage (decoder + imm)
    id_stage id_stage_inst (
        .IR(IR),
        .FT_ID(FT_ID),
        .MemtoReg_ID(MemtoReg_ID),
        .RegWrite_ID(RegWrite_ID),
        .Branch_ID(Branch_ID),
        .MemWrite_ID(MemWrite_ID),
        .MemRead_ID(MemRead_ID),
        .ALUSrc_ID(ALUSrc_ID),
        .ALUOp_ID(ALUOp_ID),
        .DMSE_ID(DMSE_ID),
        .ALUorSHIFT_ID(ALUorSHIFT_ID),
        .RS1_PC_ID(RS1_PC_ID),
        .RS1_Z_ID(RS1_Z_ID),
        .RD_ID(RD_ID),
        .IMM_VAL_EXT_ID(IMM_VAL_EXT_ID)
    );

    rf rf_inst (
        .CLK(CLK),
        .RNUM1(`IR_RS1), .RDATA1(RF_DATA1),
        .RNUM2(`IR_RS2), .RDATA2(RF_DATA2),
        .WNUM(RegWrite_MW ? RD_MW : 5'b00000), .WDATA(RD_VAL_WB)
    );

    // フラッシュ信号（分岐成立時）
    wire flush_FD = isBranch_E;
    wire flush_DE = isBranch_E;

    // フォワーディング制御
    wire [1:0] ForwardA;
    wire [1:0] ForwardB;

    // ハザード検出
    wire hazard_stall;
    hazard_detection_unit hdu_inst (
        .RS1_ID(`IR_RS1),
        .RS2_ID(`IR_RS2),
        .RS1_PC_ID(RS1_PC_ID),
        .RS1_Z_ID(RS1_Z_ID),
        .FT_ID(FT_ID),
        .RD_DE(RD_DE),
        .MemRead_DE(MemRead_DE),
        .hazard_stall(hazard_stall)
    );

    // ストール線生成（assignに変更）
    assign stall_FD = hazard_stall;
    assign stall_DE = hazard_stall;
    assign stall_IF = hazard_stall;

    // パイプラインレジスタ集約
    pipeline_regs pipeline_regs_inst (
        .CLK(CLK),
        .RST(RST),

        // 追加: フラッシュ
        .flush_FD(flush_FD),
        .flush_DE(flush_DE),
        
        .stall_FD(stall_FD),
        .stall_DE(stall_DE),

        // IF/ID
        .PC_IF(PC_IF), .IDATA_IF(IDATA_IF), .PC4_IF(PC4_IF),
        .PC_FD(PC_FD), .IDATA_FD(IDATA_FD), .PC4_FD(PC4_FD),

        // ID -> EX 入力
        .RF_DATA1(RF_DATA1), .RF_DATA2(RF_DATA2),
        .ALUOp_ID(ALUOp_ID),
        .RD_ID(RD_ID),
        .RS1_ID(`IR_RS1), .RS2_ID(`IR_RS2), // 追加: RS番号
        .IMM_VAL_EXT_ID(IMM_VAL_EXT_ID),
        .ALUSrc_ID(ALUSrc_ID),
        .FT_ID(FT_ID),
        .RS1_PC_ID(RS1_PC_ID), .RS1_Z_ID(RS1_Z_ID),
        .MemtoReg_ID(MemtoReg_ID),
        .RegWrite_ID(RegWrite_ID),
        .Branch_ID(Branch_ID),
        .MemWrite_ID(MemWrite_ID),
        .MemRead_ID(MemRead_ID),
        .ALUorSHIFT_ID(ALUorSHIFT_ID),
        .DMSE_ID(DMSE_ID),

        // ID/EX 出力
        .PC_DE(PC_DE), .PC4_DE(PC4_DE),
        .RF_DATA1_DE(RF_DATA1_DE), .RF_DATA2_DE(RF_DATA2_DE),
        .ALUOp_DE(ALUOp_DE),
        .IMM_VAL_EXT_DE(IMM_VAL_EXT_DE),
        .RD_DE(RD_DE),
        .RS1_DE(RS1_DE), .RS2_DE(RS2_DE), // 追加
        .RS1_PC_DE(RS1_PC_DE), .RS1_Z_DE(RS1_Z_DE),
        .MemtoReg_DE(MemtoReg_DE),
        .RegWrite_DE(RegWrite_DE),
        .ALUSrc_DE(ALUSrc_DE),
        .FT_DE(FT_DE),
        .Branch_DE(Branch_DE),
        .MemWrite_DE(MemWrite_DE),
        .MemRead_DE(MemRead_DE),
        .ALUorSHIFT_DE(ALUorSHIFT_DE),
        .DMSE_DE(DMSE_DE),

        // EX -> MEM 入力
        .ALU_VAL_E(ALU_VAL_E), .STORE_VAL_E(STORE_VAL_E),

        // EX/MEM 出力
        .PC4_EM(PC4_EM), .ALU_VAL_EM(ALU_VAL_EM), .STORE_VAL_EM(STORE_VAL_EM),
        .RD_EM(RD_EM),
        .MemtoReg_EM(MemtoReg_EM),
        .RegWrite_EM(RegWrite_EM),
        .MemWrite_EM(MemWrite_EM),
        .MemRead_EM(MemRead_EM),
        .DMSE_EM(DMSE_EM),

        // MEM/WB 出力
        .PC4_MW(PC4_MW), .ALU_VAL_MW(ALU_VAL_MW),
        .RD_MW(RD_MW),
        .MemtoReg_MW(MemtoReg_MW),
        .RegWrite_MW(RegWrite_MW)
    );

    // フォワーディングユニット
    forwarding_unit fu_inst (
        .RS1_DE(RS1_DE),
        .RS2_DE(RS2_DE),
        .RD_EM(RD_EM),
        .RD_MW(RD_MW),
        .RegWrite_EM(RegWrite_EM),
        .RegWrite_MW(RegWrite_MW),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB)
    );

    // EX stage
    ex_stage ex_stage_inst (
        .PC_DE(PC_DE),
        .ALUSrc_DE(ALUSrc_DE),
        .ALUOp_DE(ALUOp_DE),
        .Branch_DE(Branch_DE),
        .ALUorSHIFT_DE(ALUorSHIFT_DE),
        .FT_DE(FT_DE),
        .RF_DATA1_DE(RF_DATA1_DE),
        .RF_DATA2_DE(RF_DATA2_DE),
        .IMM_VAL_EXT_DE(IMM_VAL_EXT_DE),
        .RS1_PC_DE(RS1_PC_DE),
        .RS1_Z_DE(RS1_Z_DE),

        // 追加: フォワーディング
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .ALU_VAL_EM(ALU_VAL_EM),
        .RD_VAL_WB(RD_VAL_WB),

        .ALU_VAL_E(ALU_VAL_E),
        .STORE_VAL_E(STORE_VAL_E),
        .isBranch_E(isBranch_E),
        .PC_IMM_E(PC_IMM_E)
    );

    // MEM stage（origin準拠）
    mem_stage #(
        .DMEM_BASE(DMEM_BASE),
        .DMEM_SIZE(DMEM_SIZE),
        .DMEM_FILE(DMEM_FILE)
    ) mem_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .MemWrite_EM(MemWrite_EM),
        .MemRead_EM(MemRead_EM),
        .DMSE_EM(DMSE_EM),
        .ALU_VAL_EM(ALU_VAL_EM),
        .STORE_VAL_EM(STORE_VAL_EM),
        .MEM_DATA_M(MEM_DATA_M)
    );

// MEM→WB ラッチ
    always @(posedge CLK or posedge RST) begin
        if (RST) MEM_DATA_MW <= 32'h0000_0000;
        else     MEM_DATA_MW <= MEM_DATA_M;
    end

// WB stage（Mux）
    wb_stage wb_stage_inst (
        .MemtoReg_MW(MemtoReg_MW),
        .MEM_DATA_MW(MEM_DATA_MW),
        .PC4_MW(PC4_MW),
        .ALU_VAL_MW(ALU_VAL_MW),
        .RD_VAL_WB(RD_VAL_WB)
    );
endmodule