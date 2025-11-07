module if_stage
    #(
        parameter IMEM_BASE = 32'h0000_0000,
        parameter IMEM_SIZE = 32768,	// 32kW = 128kB
        parameter IMEM_FILE = "prog.mif"
    )
    (
        input  CLK,
        input  RST,
        input  isBranch_E,
        input  [31:0] PC_IMM_E,
        output reg [31:0] PC_IF,
        output [31:0] PC4_IF,
        output [31:0] IDATA_IF
    );

    // IMEM
    reg [31:0] imem[0:IMEM_SIZE-1];
    initial begin
        $readmemh(IMEM_FILE, imem);
    end

    assign PC4_IF = PC_IF + 4;

    // TODO: 分岐成立時のパイプライン・フラッシュ
    // - EX で isBranch_E=1 のサイクルに IF/ID レジスタ(PC_FD/IDATA_FD/PC4_FD)を NOP/0 にクリアする
    // - 実装案: pipeline_regs に flush_FD 入力を追加し、ここから isBranch_E を1サイクルパルスで与える
    // - 優先度: RST > flush > stall(将来追加時)
    // - 必要に応じて ID/EX もフラッシュ

    always @(posedge CLK or posedge RST) begin
        if (RST)
            PC_IF <= 32'h0000_0000;
        else if (isBranch_E)
            PC_IF <= PC_IMM_E;
        else
            PC_IF <= PC4_IF;
    end

    assign IDATA_IF = imem[PC_IF[31:2]];

endmodule