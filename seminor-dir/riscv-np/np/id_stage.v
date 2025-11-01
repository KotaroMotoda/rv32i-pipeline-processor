`include "riscv.vh"
`include "inst.vh"
`include "alu.vh"

module id_stage (
    // 11 control signals
    output reg [2:0]  FT_ID,
    // output reg [4:0]  IALU_ID, ALUOpで代替
    output reg [1:0]  MemtoReg_ID,
    output reg        RegWrite_ID,
    output reg        Branch_ID,
    output reg        MemWrite_ID, // TODO一応1'b0で定義
    output reg [1:0]  MemRead_ID, 
    output reg        ALUSrc_ID, // 即値(1) or レジスタ(0)
    output reg [4:0]  ALUOp_ID, // IALUはこれで代替.
    output reg        DMSE_ID,  // load命令の符号拡張制御(0で符号なしで0を頭に追加.,1で符号ありで最上位bitを頭に追加)
    output reg        RegDst_ID, // TODO一応1'b0で定義. 書き込み先レジスタがrd(1) or rt(0)
    output reg        ALUorSHIFT_ID, // TODO一応1'b0で定義. ALU(1) or シフト命令(0)

    // data path
    input      [31:0] IR,
    output reg        RS1_PC_ID, // auipc, jal, jalr 用
    output reg        RS1_Z_ID, // lui 用
    // output reg        PC_E_ID, // これをBranch_IDで代替
    output reg [4:0]  RD_ID, // 書き込み先レジスタ
    output reg [4:0]  RT_ID, // ← 追加: 書き込み先を rs2(rt) にする場合用
    output reg [31:0] IMM_VAL_EXT_ID // 拡張後の即値
);
    // デコード
    always @(*) begin
        FT_ID       = 3'b000;
        MemtoReg_ID = 2'b00;
        RegWrite_ID = 1'b0;
        Branch_ID   = 1'b0;
        MemWrite_ID = 1'b0;
        MemRead_ID  = 2'b00;
        ALUSrc_ID   = 1'b0;
        ALUOp_ID    = `IADD;
        DMSE_ID     = 1'b0;
        RegDst_ID   = 1'b0;  // 既定は rt 選択（RegWriteが1の命令で上書き）
        ALUorSHIFT_ID = 1'b0;

        RS1_PC_ID   = 1'b0;
        RS1_Z_ID    = 1'b0;
        // RD_ID       = 5'b00000;
        // IMM_VAL_EXT_ID = 32'h0000_0000;

        case (`IR_OP)
            `OP_LUI: begin 
                FT_ID       = `FT_U;
                RS1_Z_ID    = 1'b1;
                RegWrite_ID = 1'b1;
                RegDst_ID   = 1'b1; // rd を選択
                ALUSrc_ID   = 1'b1;
            end
            `OP_AUIPC: begin
                FT_ID       = `FT_U;
                RS1_PC_ID   = 1'b1;
                RegWrite_ID = 1'b1;
                RegDst_ID   = 1'b1; // rd
                ALUSrc_ID   = 1'b1;
            end
            `OP_JAL: begin
                FT_ID       = `FT_J;
                RS1_PC_ID   = 1'b1;
                Branch_ID   = 1'b1;
                MemtoReg_ID = 2'b10;
                RegWrite_ID = 1'b1;
                RegDst_ID   = 1'b1; // rd
                ALUSrc_ID   = 1'b1;
            end
            `OP_JALR: begin
                FT_ID       = `FT_I;
                Branch_ID   = 1'b1;
                MemtoReg_ID = 2'b10;
                RegWrite_ID = 1'b1;
                RegDst_ID   = 1'b1; // rd
                ALUSrc_ID   = 1'b1;
            end
            `OP_BR: begin
                FT_ID       = `FT_B;
                Branch_ID   = 1'b1;
                ALUSrc_ID   = 1'b0;
                RegDst_ID   = 1'b0; // don't care（書き込みしない）
                case(`IR_F3)
                    3'b000: ALUOp_ID = `IADD; // beq(仮)
                    3'b001: ALUOp_ID = `ISUB; // bne
                    3'b100: ALUOp_ID = `ISUB; // blt
                    3'b101: ALUOp_ID = `IADD; // bge
                    3'b110: ALUOp_ID = `ISUB; // bltu
                    3'b111: ALUOp_ID = `IADD; // bgeu
                endcase
            end
            `OP_LOAD: begin
                FT_ID       = `FT_I;
                MemtoReg_ID = 2'b01;
                RegWrite_ID = 1'b1;
                RegDst_ID   = 1'b1; // rd
                ALUSrc_ID   = 1'b1;
                case(`IR_F3)
                    3'b000: begin DMSE_ID = 1'b1; end // lb
                    3'b001: begin DMSE_ID = 1'b1; end // lh
                    3'b010: begin DMSE_ID = 1'b1; end // lw
                    3'b100: DMSE_ID = 1'b0; // lbu
                    3'b101: DMSE_ID = 1'b0; // lhu
                    3'b110: DMSE_ID = 1'b0; // lwu
                endcase
            end
            `OP_STORE: begin
                FT_ID       = `FT_S;
                RegWrite_ID = 1'b0;
                RegDst_ID   = 1'b0; // don't care
                ALUSrc_ID   = 1'b1;
            end
            `OP_FUNC1: begin // I-type ALU
                FT_ID       = `FT_I;
                RegWrite_ID = 1'b1;
                RegDst_ID   = 1'b1; // rd
                ALUSrc_ID   = 1'b1;
                case(`IR_F3)
                    3'b000: ALUOp_ID = `IADD; // addi
                    3'b001: if(`IR_F7 == 7'b0000000) ALUOp_ID = `ISLL; // slli
                    3'b010: ALUOp_ID = `IADD; // slti(仮)
                    3'b011: ALUOp_ID = `IADD; // sltiu(仮)
                    3'b100: ALUOp_ID = `IXOR; // xori
                    3'b101: begin
                        if(`IR_F7 == 7'b0000000) ALUOp_ID = `ISRL; // srli
                        else if(`IR_F7 == 7'b0100000) ALUOp_ID = `ISRA; // srai
                    end
                    3'b110: ALUOp_ID = `IOR; // ori
                    3'b111: ALUOp_ID = `IAND; // andi
                endcase
            end
            `OP_FUNC2: begin // R-type
                FT_ID       = `FT_R;
                RegWrite_ID = 1'b1;
                RegDst_ID   = 1'b1; // rd
                ALUSrc_ID   = 1'b0;
                case(`IR_F3)
                    3'b000: begin
                        if(`IR_F7 == 7'b0000000) ALUOp_ID = `IADD; // add
                        else if(`IR_F7 == 7'b0100000) ALUOp_ID = `ISUB; // sub
                    end
                    3'b001: if(`IR_F7 == 7'b0000000) ALUOp_ID = `ISLL; // sll
                    3'b010: if(`IR_F7 == 7'b0000000) ALUOp_ID = `IADD; // slt(仮)
                    3'b011: if(`IR_F7 == 7'b0000000) ALUOp_ID = `IADD; // sltu(仮)
                    3'b100: if(`IR_F7 == 7'b0000000) ALUOp_ID = `IXOR; // xor
                    3'b101: begin
                        if(`IR_F7 == 7'b0000000) ALUOp_ID = `ISRL; // srl
                        else if(`IR_F7 == 7'b0100000) ALUOp_ID = `ISRA; // sra
                    end
                    3'b110: if(`IR_F7 == 7'b0000000) ALUOp_ID = `IOR; // or
                    3'b111: if(`IR_F7 == 7'b0000000) ALUOp_ID = `IAND; // and
                endcase
            end
        endcase

        RD_ID = `IR_RD;
        RT_ID = `IR_RS2; // rs2 を rt として使用
    end

    // 即値抽出（符号拡張）
    always @(*) begin
        IMM_VAL_EXT_ID = { {20{IR[31]}}, IR[31:20] }; // I-type default
        case (FT_ID)
            `FT_S: IMM_VAL_EXT_ID = { {20{IR[31]}}, `IR_F7, `IR_RD };
            `FT_B: IMM_VAL_EXT_ID = { {20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0 };
            `FT_U: IMM_VAL_EXT_ID = { IR[31:12], 12'h000 };
            `FT_J: IMM_VAL_EXT_ID = { {11{IR[31]}}, IR[31], IR[19:12], IR[20], IR[30:21], 1'b0 };
        endcase
    end

endmodule