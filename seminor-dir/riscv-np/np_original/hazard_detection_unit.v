`include "riscv.vh"

module hazard_detection_unit (
    input  [4:0] RS1_ID,
    input  [4:0] RS2_ID,
    input        RS1_PC_ID,
    input        RS1_Z_ID,
    input  [2:0] FT_ID,
    input  [4:0] RD_DE,
    input  [1:0] MemRead_DE,   // 00: none
    output       hazard_stall
);
    // rs1/rs2 を本当に使う命令だけを対象にする
    wire use_rs1 = ~(RS1_PC_ID | RS1_Z_ID);                 // PCやゼロを使う場合は依存なし
    wire use_rs2 = (FT_ID == `FT_R) | (FT_ID == `FT_B) | (FT_ID == `FT_S); // R,B,S は rs2 使用

    assign hazard_stall =
        (MemRead_DE != 2'b00) &&
        (RD_DE != 5'd0) &&
        ( (use_rs1 && (RD_DE == RS1_ID)) ||
          (use_rs2 && (RD_DE == RS2_ID)) );
endmodule