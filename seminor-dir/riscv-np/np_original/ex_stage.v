`include "riscv.vh"
`include "inst.vh"
`include "alu.vh"

module ex_stage (
    // PC
    input  [31:0] PC_DE,
    // control signals
    input         ALUSrc_DE,
    input  [4:0]  ALUOp_DE,
    input         Branch_DE,
    input         ALUorSHIFT_DE,
    input  [2:0]  FT_DE,
    // data path
    input  [31:0] RF_DATA1_DE,
    input  [31:0] RF_DATA2_DE,
    input  [31:0] IMM_VAL_EXT_DE,
    input         RS1_PC_DE,
    input         RS1_Z_DE,

    // フォワーディング制御＋データ
    input  [1:0]  ForwardA,
    input  [1:0]  ForwardB,
    input  [31:0] ALU_VAL_EM,   // EX/MEM からの前段結果
    input  [31:0] RD_VAL_WB,    // MEM/WB からの書き戻し値（最終値）

    input [1:0] PACK_SIZE_DE,

    output [31:0] ALU_VAL_E,
    output [31:0] STORE_VAL_E,
    output        isBranch_E,
    output [31:0] PC_IMM_E
);
    // lui/auipc 用 RS1 値選択
    wire [31:0] baseA = RS1_PC_DE ? PC_DE : (RS1_Z_DE ? 32'h0000_0000 : RF_DATA1_DE);

    // フォワーディング適用（RS1_PC/RS1_Z の場合はフォワードしない）
    reg [31:0] opA;
    always @(*) begin
        if (RS1_PC_DE || RS1_Z_DE) begin
            opA = baseA;
        end else begin
            case (ForwardA)
                2'b10: opA = ALU_VAL_EM; // EX/MEM
                2'b01: opA = RD_VAL_WB;  // MEM/WB
                default: opA = RF_DATA1_DE; // ID/EX
            endcase
        end
    end

    // Bオペランドのフォワード（ストアデータにも使う）
    reg [31:0] src2_fwd_r;
    always @(*) begin
        case (ForwardB)
            2'b10: src2_fwd_r = ALU_VAL_EM; // EX/MEM
            2'b01: src2_fwd_r = RD_VAL_WB;  // MEM/WB
            default: src2_fwd_r = RF_DATA2_DE; // ID/EX
        endcase
    end
    wire [31:0] src2_fwd = src2_fwd_r;

    // MEM ストア用データ（フォワード後）
    assign STORE_VAL_E = src2_fwd;

    // 第2オペランド選択（即値 or レジスタ/フォワード）
    wire [31:0] data2 = ALUSrc_DE ? IMM_VAL_EXT_DE : src2_fwd;

    // ALU
    wire [31:0] alu_val_e;
    alu alu_inst (
        .A(opA),
        .B(data2),
        .C(ALUOp_DE),
        .P(PACK_SIZE_DE),
        .Y(alu_val_e)
    );

    // SHIFT
    wire [4:0] shamt = ALUSrc_DE ? IMM_VAL_EXT_DE[4:0] : src2_fwd[4:0];
    wire [31:0] shift_val_e;
    shift shift_inst (
        .A(opA),
        .B(shamt),
        .C(ALUOp_DE),
        .Y(shift_val_e)
    );

    // ALU/SHIFT の結果選択
    assign ALU_VAL_E = ALUorSHIFT_DE ? shift_val_e : alu_val_e;

    // 分岐ターゲット生成
    wire [31:0] jalr_tgt = { alu_val_e[31:1], 1'b0 }; // JALR: LSB=0
    wire [31:0] br_addr_e = (FT_DE == `FT_I) ? jalr_tgt : (PC_DE + IMM_VAL_EXT_DE);

    // 分岐許可信号（B型のみ条件を見る）
    assign isBranch_E = Branch_DE && !((FT_DE == `FT_B) && !alu_val_e[0]);

    // IF 段へ渡す分岐先
    assign PC_IMM_E   = br_addr_e;

endmodule