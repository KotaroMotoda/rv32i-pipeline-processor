`include "riscv.vh"
`include "inst.vh"
`include "alu.vh"

module id_stage (
    // 11 control signals
    output reg [2:0]  FT_ID,
    output reg [1:0]  MemtoReg_ID,
    output reg        RegWrite_ID,
    output reg        Branch_ID,
    output reg [1:0]  MemWrite_ID,     // 00:none, 01:byte, 10:half, 11:word
    output reg [1:0]  MemRead_ID,      // 00:none, 01:byte, 10:half, 11:word
    output reg        ALUSrc_ID,
    output reg [4:0]  ALUOp_ID,
    output reg        DMSE_ID,
    output reg        ALUorSHIFT_ID,
    // data path
    input      [31:0] IR,
    output reg        RS1_PC_ID,
    output reg        RS1_Z_ID,
    output reg [4:0]  RD_ID,
    output reg [31:0] IMM_VAL_EXT_ID
);
    // デコード
    always @(*) begin
        // 既定値
        FT_ID         = 3'b000;
        MemtoReg_ID   = 2'b00;
        RegWrite_ID   = 1'b0;
        Branch_ID     = 1'b0;
        MemWrite_ID   = 2'b00;  // ← 2bit化
        MemRead_ID    = 2'b00;
        ALUSrc_ID     = 1'b0;
        ALUOp_ID      = `IADD;
        DMSE_ID       = 1'b0;
        ALUorSHIFT_ID = 1'b0;
        RS1_PC_ID     = 1'b0;
        RS1_Z_ID      = 1'b0;

        case (`IR_OP)
            `OP_LUI: begin
                FT_ID         = `FT_U;
                RS1_Z_ID      = 1'b1;
                RegWrite_ID   = 1'b1;
                ALUSrc_ID     = 1'b1;
            end
            `OP_AUIPC: begin
                FT_ID         = `FT_U;
                RS1_PC_ID     = 1'b1;
                RegWrite_ID   = 1'b1;
                ALUSrc_ID     = 1'b1;
            end
            `OP_JAL: begin
                FT_ID         = `FT_J;
                RS1_PC_ID     = 1'b1;
                Branch_ID     = 1'b1;
                MemtoReg_ID   = 2'b10; // PC+4
                RegWrite_ID   = 1'b1;
                ALUSrc_ID     = 1'b1;
            end
            `OP_JALR: begin
                FT_ID         = `FT_I;
                Branch_ID     = 1'b1;
                MemtoReg_ID   = 2'b10; // PC+4
                RegWrite_ID   = 1'b1;
                ALUSrc_ID     = 1'b1;  // rs1 + imm
            end
            `OP_BR: begin
                FT_ID         = `FT_B;
                Branch_ID     = 1'b1;
                ALUSrc_ID     = 1'b0;  // rs2
                // 分岐条件は ALU が bit0 で返す前提（origin と同じ）
                case (`IR_F3)
                    3'b000: ALUOp_ID = `equal;                 // beq
                    3'b001: ALUOp_ID = `notEqual;              // bne
                    3'b100: ALUOp_ID = `lessThan;              // blt
                    3'b101: ALUOp_ID = `greaterEqual;          // bge
                    3'b110: ALUOp_ID = `lessThanUnsigned;      // bltu
                    3'b111: ALUOp_ID = `greaterEqualUnsigned;  // bgeu
                    default: ALUOp_ID = `IADD;
                endcase
            end
            `OP_LOAD: begin
                FT_ID         = `FT_I;
                MemtoReg_ID   = 2'b01; // DMEM
                RegWrite_ID   = 1'b1;
                ALUSrc_ID     = 1'b1;  // rs1 + imm
                case (`IR_F3)
                    3'b000: begin MemRead_ID = 2'b01; DMSE_ID = 1'b1; end // lb
                    3'b001: begin MemRead_ID = 2'b10; DMSE_ID = 1'b1; end // lh
                    3'b010: begin MemRead_ID = 2'b11; DMSE_ID = 1'b1; end // lw
                    3'b100: begin MemRead_ID = 2'b01; DMSE_ID = 1'b0; end // lbu
                    3'b101: begin MemRead_ID = 2'b10; DMSE_ID = 1'b0; end // lhu
                    3'b110: begin MemRead_ID = 2'b11; DMSE_ID = 1'b0; end // lwu
                    default: begin MemRead_ID = 2'b00; DMSE_ID = 1'b0; end
                endcase
            end
            `OP_STORE: begin
                FT_ID         = `FT_S;
                RegWrite_ID   = 1'b0;
                ALUSrc_ID     = 1'b1;  // rs1 + imm（アドレス計算）
                case (`IR_F3)
                    3'b000: MemWrite_ID = 2'b01; // sb
                    3'b001: MemWrite_ID = 2'b10; // sh
                    3'b010: MemWrite_ID = 2'b11; // sw
                    default: MemWrite_ID = 2'b00;
                endcase
            end
            `OP_FUNC1: begin // I-type ALU
                FT_ID         = `FT_I;
                RegWrite_ID   = 1'b1;
                ALUSrc_ID     = 1'b1;  // imm
                case (`IR_F3)
                    3'b000: ALUOp_ID = `IADD; // addi
                    3'b001: begin // slli
                        if (`IR_F7 == 7'b0000000) begin ALUOp_ID = `ISLL; ALUorSHIFT_ID = 1'b1; end
                    end
                    3'b010: ALUOp_ID = `lessThan;          // slti
                    3'b011: ALUOp_ID = `lessThanUnsigned;  // sltiu
                    3'b100: ALUOp_ID = `IXOR;              // xori
                    3'b101: begin // srli/srai
                        if (`IR_F7 == 7'b0000000) begin ALUOp_ID = `ISRL; ALUorSHIFT_ID = 1'b1; end
                        else if (`IR_F7 == 7'b0100000) begin ALUOp_ID = `ISRA; ALUorSHIFT_ID = 1'b1; end
                    end
                    3'b110: ALUOp_ID = `IOR;               // ori
                    3'b111: ALUOp_ID = `IAND;              // andi
                endcase
            end
            `OP_FUNC2: begin // R-type
                FT_ID         = `FT_R;
                RegWrite_ID   = 1'b1;
                ALUSrc_ID     = 1'b0;  // rs2
                case (`IR_F3)
                    3'b000: begin
                        if (`IR_F7 == 7'b0000000) ALUOp_ID = `IADD; // add
                        else if (`IR_F7 == 7'b0100000) ALUOp_ID = `ISUB; // sub
                    end
                    3'b001: if (`IR_F7 == 7'b0000000) begin ALUOp_ID = `ISLL; ALUorSHIFT_ID = 1'b1; end // sll
                    3'b010: if (`IR_F7 == 7'b0000000) ALUOp_ID = `lessThan;             // slt
                    3'b011: if (`IR_F7 == 7'b0000000) ALUOp_ID = `lessThanUnsigned;     // sltu
                    3'b100: if (`IR_F7 == 7'b0000000) ALUOp_ID = `IXOR;                 // xor
                    3'b101: begin
                        if (`IR_F7 == 7'b0000000) begin ALUOp_ID = `ISRL; ALUorSHIFT_ID = 1'b1; end // srl
                        else if (`IR_F7 == 7'b0100000) begin ALUOp_ID = `ISRA; ALUorSHIFT_ID = 1'b1; end // sra
                    end
                    3'b110: if (`IR_F7 == 7'b0000000) ALUOp_ID = `IOR;                  // or
                    3'b111: if (`IR_F7 == 7'b0000000) ALUOp_ID = `IAND;                 // and
                endcase
            end
            default: begin
                // 既定値のまま
            end
        endcase

        RD_ID = `IR_RD;
        // RT_ID は削除
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