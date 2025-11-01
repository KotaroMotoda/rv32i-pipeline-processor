`include "riscv.vh"
`include "inst.vh"
`include "alu.vh"

module ex_stage (
    input  [31:0] RF_DATA1_DE,
    input  [31:0] RF_DATA2_DE,
    input  [31:0] IMM_VAL_DE,
    input         ALUSrc_DE,
    input         RS1_PC_DE,
    input         RS1_Z_DE,
    input  [2:0]  FT_DE,
    input  [31:0] PC_DE,
    input  [4:0]  IALU_DE,
    output [31:0] RD_VAL_E,
    output        isBranch_E,
    output [31:0] PC_IMM_E
);
    wire [31:0] data1 = RS1_PC_DE ? PC_DE : (RS1_Z_DE ? 32'h0000_0000 : RF_DATA1_DE);
    reg  [31:0] imm_shifted;

    always @(*) begin
        if (FT_DE == `FT_B || FT_DE == `FT_J)
            imm_shifted = IMM_VAL_DE << 2;
        else
            imm_shifted = IMM_VAL_DE;
    end

    wire [31:0] data2 = ALUSrc_DE ? imm_shifted : RF_DATA2_DE;

    alu alu_inst (
        .A(data1),
        .B(data2),
        .C(IALU_DE),
        .Y(RD_VAL_E)
    );

    // 元コード準拠（分岐未実装）
    assign isBranch_E = 1'b0;
    assign PC_IMM_E   = PC_DE + imm_shifted;

endmodule