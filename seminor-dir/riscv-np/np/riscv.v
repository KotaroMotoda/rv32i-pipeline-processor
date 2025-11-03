`include "riscv.vh"
`include "inst.vh"
`include "alu.vh"
`define LITTLE_ENDIAN

module riscv
    #(
        parameter IMEM_BASE = 32'h0000_0000,
        parameter IMEM_SIZE = 32768,	// 32kW = 128kB
        parameter IMEM_FILE = "prog.mif",
        parameter DMEM_BASE = 32'h0010_0000,
        parameter DMEM_SIZE = 32768,	// 32kW = 128kB
        parameter DMEM_FILE = "data.mif"
    )
    (
        input  CLK,
        input  RSTN,
        output reg [31:0] WE_RD_VAL
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
    wire        RegDst_ID;          // ← 追加
    wire        ALUorSHIFT_ID;      // ← 追加
    wire        MemWrite_ID;        // ← 追加
    wire [1:0]  MemRead_ID;         // ← 追加
    wire [4:0]  RD_ID;
    wire [4:0]  RT_ID;
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
    wire [31:0] IMM_VAL_EXT_DE;     // ← 名称合わせ
    wire [4:0]  RD_DE;
    wire [4:0]  RT_DE;
    wire        RS1_PC_DE;
    wire        RS1_Z_DE;
    wire [1:0]  MemtoReg_DE;
    wire        RegWrite_DE;
    wire        RegDst_DE;          // ← 追加
    wire        ALUSrc_DE;
    wire        Branch_DE;          // ← 追加
    wire        ALUorSHIFT_DE;      // ← 追加
    wire        DMSE_DE;            // ← 追加
    wire [1:0]  MemRead_DE;         // ← 追加
    wire        MemWrite_DE;        // ← 追加
    wire [2:0]  FT_DE;

    // EX stage
    wire [31:0] ALU_VAL_E;          // ← RD_VAL_E → ALU_VAL_E
    wire [31:0] STORE_VAL_E;        // ← 追加
    wire        isBranch_E;
    wire [31:0] PC_IMM_E;

    // EX/MEM pipeline
    wire [31:32] dummy_unused = 0;  // 置き場なしの回避が必要なら削除
    wire [31:0] PC4_EM;
    wire [31:0] ALU_VAL_EM;         // ← RD_VAL_EM → ALU_VAL_EM
    wire [31:0] STORE_VAL_EM;       // ← 追加
    wire [4:0]  RD_EM;
    wire [4:0]  RT_EM;
    wire [1:0]  MemtoReg_EM;
    wire        RegWrite_EM;
    wire        RegDst_EM;
    wire        MemWrite_EM;        // ← 追加
    wire [1:0]  MemRead_EM;         // ← 追加
    wire        DMSE_EM;            // ← 追加

    // MEM/WB pipeline
    wire [31:0] PC4_MW;
    wire [31:0] ALU_VAL_MW;         // ← RD_VAL_MW → ALU_VAL_MW
    wire [4:0]  RD_MW;
    wire [4:0]  RT_MW;
    wire [1:0]  MemtoReg_MW;
    wire        RegWrite_MW;
    wire        RegDst_MW;

    // MEM data path (未実装のまま)
    reg [31:0] MEM_DATA_MW;

    // WB stage
    wire [31:0] RD_VAL_WB;

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
        .PC_IF(PC_IF),
        .PC4_IF(PC4_IF),
        .IDATA_IF(IDATA_IF)
    );

    // ID stage (decoder + imm)
    id_stage id_stage_inst (
        .IR(IR),
        .FT_ID(FT_ID),
        .ALUOp_ID(ALUOp_ID),
        .MemtoReg_ID(MemtoReg_ID),
        .RegWrite_ID(RegWrite_ID),
        .ALUSrc_ID(ALUSrc_ID),
        .DMSE_ID(DMSE_ID),
        .RS1_PC_ID(RS1_PC_ID),
        .RS1_Z_ID(RS1_Z_ID),
        .Branch_ID(Branch_ID),
        .MemWrite_ID(MemWrite_ID),      // ← 追加
        .MemRead_ID(MemRead_ID),        // ← 追加
        .RegDst_ID(RegDst_ID),
        .ALUorSHIFT_ID(ALUorSHIFT_ID),  // ← 追加
        .RD_ID(RD_ID),
        .RT_ID(RT_ID),
        .IMM_VAL_EXT_ID(IMM_VAL_EXT_ID)
    );

    rf rf_inst (
        .CLK(CLK),
        .RNUM1(`IR_RS1), .RDATA1(RF_DATA1),
        .RNUM2(`IR_RS2), .RDATA2(RF_DATA2),
        .WNUM(RegWrite_MW ? (RegDst_MW ? RD_MW : RT_MW) : 5'b00000), .WDATA(RD_VAL_WB)
    );

    // パイプラインレジスタ集約
    pipeline_regs pipeline_regs_inst (
        .CLK(CLK),
        .RST(RST),

        // IF/ID
        .PC_IF(PC_IF),
        .IDATA_IF(IDATA_IF),
        .PC4_IF(PC4_IF),
        .PC_FD(PC_FD),
        .IDATA_FD(IDATA_FD),
        .PC4_FD(PC4_FD),

        // ID -> EX 入力
        .RF_DATA1(RF_DATA1),
        .RF_DATA2(RF_DATA2),
        .ALUOp_ID(ALUOp_ID),
        .RD_ID(RD_ID),
        .RT_ID(RT_ID),
        .IMM_VAL_EXT_ID(IMM_VAL_EXT_ID),
        .ALUSrc_ID(ALUSrc_ID),
        .FT_ID(FT_ID),
        .RS1_PC_ID(RS1_PC_ID),
        .RS1_Z_ID(RS1_Z_ID),
        .MemtoReg_ID(MemtoReg_ID),
        .RegWrite_ID(RegWrite_ID),
        .RegDst_ID(RegDst_ID),
        .Branch_ID(Branch_ID),          // ← 追加
        .MemWrite_ID(MemWrite_ID),      // ← 追加
        .MemRead_ID(MemRead_ID),        // ← 追加
        .ALUorSHIFT_ID(ALUorSHIFT_ID),  // ← 追加
        .DMSE_ID(DMSE_ID),              // ← 追加

        // ID/EX 出力
        .PC_DE(PC_DE),
        .PC4_DE(PC4_DE),
        .RF_DATA1_DE(RF_DATA1_DE),
        .RF_DATA2_DE(RF_DATA2_DE),
        .ALUOp_DE(ALUOp_DE),
        .IMM_VAL_EXT_DE(IMM_VAL_EXT_DE), // ← 名称合わせ
        .RD_DE(RD_DE),
        .RT_DE(RT_DE),
        .RS1_PC_DE(RS1_PC_DE),
        .RS1_Z_DE(RS1_Z_DE),
        .MemtoReg_DE(MemtoReg_DE),
        .RegWrite_DE(RegWrite_DE),
        .RegDst_DE(RegDst_DE),          // ← 追加
        .ALUSrc_DE(ALUSrc_DE),
        .FT_DE(FT_DE),
        .Branch_DE(Branch_DE),          // ← 追加
        .MemWrite_DE(MemWrite_DE),      // ← 追加
        .MemRead_DE(MemRead_DE),        // ← 追加
        .ALUorSHIFT_DE(ALUorSHIFT_DE),  // ← 追加
        .DMSE_DE(DMSE_DE),              // ← 追加

        // EX -> MEM 入力
        .ALU_VAL_E(ALU_VAL_E),          // ← 名称合わせ
        .STORE_VAL_E(STORE_VAL_E),      // ← 追加

        // EX/MEM 出力
        .PC4_EM(PC4_EM),
        .ALU_VAL_EM(ALU_VAL_EM),        // ← 名称合わせ
        .STORE_VAL_EM(STORE_VAL_EM),    // ← 追加
        .RD_EM(RD_EM),
        .RT_EM(RT_EM),
        .MemtoReg_EM(MemtoReg_EM),
        .RegWrite_EM(RegWrite_EM),
        .RegDst_EM(RegDst_EM),
        .MemWrite_EM(MemWrite_EM),      // ← 追加
        .MemRead_EM(MemRead_EM),        // ← 追加
        .DMSE_EM(DMSE_EM),              // ← 追加

        // MEM/WB 出力
        .PC4_MW(PC4_MW),
        .ALU_VAL_MW(ALU_VAL_MW),        // ← 名称合わせ
        .RD_MW(RD_MW),
        .RT_MW(RT_MW),
        .MemtoReg_MW(MemtoReg_MW),
        .RegWrite_MW(RegWrite_MW),
        .RegDst_MW(RegDst_MW)
    );

    // EX stage
    ex_stage ex_stage_inst (
        .PC_DE(PC_DE),
        .ALUSrc_DE(ALUSrc_DE),
        .ALUOp_DE(ALUOp_DE),
        .Branch_DE(Branch_DE),          // ← 追加
        .ALUorSHIFT_DE(ALUorSHIFT_DE),  // ← 追加
        .FT_DE(FT_DE),
        .RF_DATA1_DE(RF_DATA1_DE),
        .RF_DATA2_DE(RF_DATA2_DE),
        .IMM_VAL_EXT_DE(IMM_VAL_EXT_DE),// ← 名称合わせ
        .RS1_PC_DE(RS1_PC_DE),
        .RS1_Z_DE(RS1_Z_DE),

        .ALU_VAL_E(ALU_VAL_E),          // ← 追加
        .STORE_VAL_E(STORE_VAL_E),      // ← 追加
        .isBranch_E(isBranch_E),
        .PC_IMM_E(PC_IMM_E)
    );

    // MEM stage（ダミー。元コードではデータメモリ未実装）
    mem_stage mem_stage_inst (
        .CLK(CLK)
    );

    // WB stage（Mux）
    wb_stage wb_stage_inst (
        .MemtoReg_MW(MemtoReg_MW),
        .MEM_DATA_MW(MEM_DATA_MW),
        .PC4_MW(PC4_MW),
        .RD_VAL_MW(ALU_VAL_MW),         // ← ローカル名は ALU_VAL_MW に接続
        .RD_VAL_WB(RD_VAL_WB)
    );

    // 出力レジスタ（元コード同様、非同期リセットなし）
    always @(posedge CLK) begin
        WE_RD_VAL <= RD_VAL_WB;
    end

endmodule