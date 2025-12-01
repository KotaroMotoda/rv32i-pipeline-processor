`include "riscv.vh"
`include "inst.vh"
`include "alu.vh"
`define LITTLE_ENDIAN

module riscv_core (
    input  wire        CLK,
    input  wire        RSTN,

    // MEMバス（コア→トップ）
    output wire [31:0] ALU_VAL_EM,
    output wire [31:0] STORE_VAL_EM,
    output wire [1:0]  MemWrite_EM,
    output wire [1:0]  MemRead_EM,
    output wire        DMSE_EM,

    // MEMバス（トップ→コア）
    input  wire [31:0] MEM_DATA_M
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

    // RF
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
    wire        RS1_PC_DE;
    wire        RS1_Z_DE;
    wire [1:0]  MemtoReg_DE;
    wire        RegWrite_DE;
    wire        ALUSrc_DE;
    wire [2:0]  FT_DE;
    wire        Branch_DE;
    wire [1:0]  MemWrite_DE;
    wire [1:0]  MemRead_DE;
    wire        ALUorSHIFT_DE;
    wire        DMSE_DE;

    // EX stage out
    wire [31:0] ALU_VAL_E;
    wire [31:0] STORE_VAL_E;
    wire        isBranch_E;
    wire [31:0] PC_IMM_E;

    // EX/MEM pipeline（ここがトップへ外出しされる）
    wire [31:0] PC4_EM_i;
    wire [4:0]  RD_EM_i;
    wire [1:0]  MemtoReg_EM_i;
    wire        RegWrite_EM_i;

    // MEM/WB pipeline
    wire [31:0] PC4_MW;
    wire [31:0] ALU_VAL_MW;
    wire [4:0]  RD_MW;
    wire [1:0]  MemtoReg_MW;
    wire        RegWrite_MW;

    // MEM データ（WB用ラッチ）
    reg  [31:0] MEM_DATA_MW;

    // IF stage（IMEMは if_stage 内部ROMを継続使用）
    if_stage if_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .isBranch_E(isBranch_E),
        .PC_IMM_E(PC_IMM_E),
        .stall_IF(1'b0),
        .PC_IF(PC_IF),
        .PC4_IF(PC4_IF),
        .IDATA_IF(IDATA_IF)
    );

    // ID stage（デコーダ）
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
        .RS1_PC_ID(RS1_PC_ID),
        .RS1_Z_ID(RS1_Z_ID),
        .RD_ID(RD_ID),
        .IMM_VAL_EXT_ID(IMM_VAL_EXT_ID)
    );

    // レジスタファイル（書き込み先は常に rd）
    rf rf_inst (
        .CLK(CLK),
        .RNUM1(`IR_RS1), .RDATA1(RF_DATA1),
        .RNUM2(`IR_RS2), .RDATA2(RF_DATA2),
        .WNUM(RegWrite_MW ? RD_MW : 5'b00000),
        .WDATA(RD_VAL_WB)
    );

    // パイプラインレジスタ（フラッシュ・ストールは未実装→flush_FDは分岐でクリア）
    pipeline_regs pipeline_regs_inst (
        .CLK(CLK),
        .RST(RST),

        .flush_FD(isBranch_E),
        .flush_DE(1'b0),
        .stall_FD(1'b0),
        .stall_DE(1'b0),

        // IF/ID
        .PC_IF(PC_IF), .IDATA_IF(IDATA_IF), .PC4_IF(PC4_IF),
        .PC_FD(PC_FD), .IDATA_FD(IDATA_FD), .PC4_FD(PC4_FD),

        // ID->EX in
        .RF_DATA1(RF_DATA1), .RF_DATA2(RF_DATA2),
        .ALUOp_ID(ALUOp_ID),
        .RD_ID(RD_ID),
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

        // ID/EX out
        .PC_DE(PC_DE), .PC4_DE(PC4_DE),
        .RF_DATA1_DE(RF_DATA1_DE), .RF_DATA2_DE(RF_DATA2_DE),
        .ALUOp_DE(ALUOp_DE),
        .IMM_VAL_EXT_DE(IMM_VAL_EXT_DE),
        .RD_DE(RD_DE),
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

        // EX->MEM in
        .ALU_VAL_E(ALU_VAL_E), .STORE_VAL_E(STORE_VAL_E),

        // EX/MEM out
        .PC4_EM(PC4_EM_i),
        .ALU_VAL_EM(ALU_VAL_EM),
        .STORE_VAL_EM(STORE_VAL_EM),
        .RD_EM(RD_EM_i),
        .MemtoReg_EM(MemtoReg_EM_i),
        .RegWrite_EM(RegWrite_EM_i),
        .MemWrite_EM(MemWrite_EM),
        .MemRead_EM(MemRead_EM),
        .DMSE_EM(DMSE_EM),

        // MEM/WB out
        .PC4_MW(PC4_MW), .ALU_VAL_MW(ALU_VAL_MW),
        .RD_MW(RD_MW),
        .MemtoReg_MW(MemtoReg_MW),
        .RegWrite_MW(RegWrite_MW)
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

        .ALU_VAL_E(ALU_VAL_E),
        .STORE_VAL_E(STORE_VAL_E),
        .isBranch_E(isBranch_E),
        .PC_IMM_E(PC_IMM_E)
    );

    // MEM→WB ラッチ（ロードデータを保持）
    always @(posedge CLK or posedge RST) begin
        if (RST) MEM_DATA_MW <= 32'h0;
        else     MEM_DATA_MW <= MEM_DATA_M;
    end

    // WB stage
    wire [31:0] RD_VAL_WB;
    wb_stage wb_stage_inst (
        .MemtoReg_MW(MemtoReg_MW),
        .MEM_DATA_MW(MEM_DATA_MW),
        .PC4_MW(PC4_MW),
        .ALU_VAL_MW(ALU_VAL_MW),
        .RD_VAL_WB(RD_VAL_WB)
    );
endmodule