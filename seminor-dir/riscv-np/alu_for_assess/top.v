module alu_top (
    input  wire         clk,
    input  wire [31:0]  A_in,
    input  wire [31:0]  B_in,
    input  wire [4:0]   C_in,   // ← ALU の C に対応
    input  wire [1:0]   P_in,   // ← ALU の P に対応
    output reg  [31:0]  Y_out
);

    // 入力をレジスタに保持
    reg [31:0] A_reg, B_reg;
    reg [4:0]  C_reg;
    reg [1:0]  P_reg;
    wire [31:0] alu_result;

    always @(posedge clk) begin
        A_reg <= A_in;
        B_reg <= B_in;
        C_reg <= C_in;
        P_reg <= P_in;
    end

    // あなたの ALU をインスタンス
    alu u_alu (
        .A (A_reg),
        .B (B_reg),
        .C (C_reg),
        .P (P_reg),
        .Y (alu_result)
    );

    // 出力をレジスタに保持
    always @(posedge clk) begin
        Y_out <= alu_result;
    end

endmodule
