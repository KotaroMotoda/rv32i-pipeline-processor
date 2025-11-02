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

    output [31:0] ALU_VAL_E,
    output [31:0] STORE_VAL_E,  // ← 追加: ストア用データ（フォワード後のrs2）
    output        isBranch_E,
    output [31:0] PC_IMM_E
);
    // 第1オペランド選択
    wire [31:0] data1 = RS1_PC_DE ? PC_DE : (RS1_Z_DE ? 32'h0000_0000 : RF_DATA1_DE);

    // 第2オペランド選択の前段: フォワーディングMUX（現状はレジスタ値をそのまま使用）
    // TODO(Forwarding):
    //   将来的に以下の3択にすること
    //     1) RF_DATA2_DE（通常）
    //     2) EX/MEM からのフォワード値（例: ALU_VAL_EM など）
    //     3) MEM/WB からのフォワード値（例: ALU_VAL_MW や RD_VAL_WB など）
    wire [31:0] src2_fwd = RF_DATA2_DE;

    // MEMストアに使う生の第2オペランド（フォワード後）をそのまま保持
    assign STORE_VAL_E = src2_fwd;

    // 第2オペランド選択（ALUSrc: 1=即値, 0=レジスタ/フォワード）
    wire [31:0] data2 = ALUSrc_DE ? IMM_VAL_EXT_DE : src2_fwd;

    // ALU（結果は一旦ローカル線へ）
    wire [31:0] alu_val_e;
    alu alu_inst (
        .A(data1),
        .B(data2),
        .C(ALUOp_DE),
        .Y(alu_val_e)
    );

    // SHIFT（シフト量は I型: IMM[4:0], R型: rs2[4:0]）
    wire [4:0] shamt = ALUSrc_DE ? IMM_VAL_EXT_DE[4:0] : src2_fwd[4:0];
    wire [31:0] shift_val_e;
    shift shift_inst (
        .A(data1),
        .B(shamt),
        .C(ALUOp_DE),
        .Y(shift_val_e)
    );

    // ALU/SHIFT の結果選択（DMEMアドレスにもこの結果を使用）
    assign ALU_VAL_E = ALUorSHIFT_DE ? shift_val_e : alu_val_e;

    // 分岐ターゲット生成
    // jalr(I型)は (rs1+imm) の bit0 を 0 にクリア、B/J は PC+IMM
    wire [31:0] jalr_tgt = { alu_val_e[31:1], 1'b0 }; // JALR: LSB=0 クリア
    wire [31:0] br_addr_e = (FT_DE == `FT_I) ? jalr_tgt : (PC_DE + IMM_VAL_EXT_DE);

    // 分岐許可信号（origin と同等の論理）
    assign isBranch_E = Branch_DE && !((FT_DE == `FT_B) && !alu_val_e[0]);

    // IF 段へ渡す分岐先
    assign PC_IMM_E   = br_addr_e;

endmodule