module mem_stage #(
    parameter DMEM_BASE = 32'h0010_0000,
    parameter DMEM_SIZE = 32768,
    parameter DMEM_FILE = "data.mif"
)(
    input         CLK,
    input         RST,

    // control
    input  [1:0]  MemWrite_EM,      // 00: no write, 01: byte, 10: h-word, 11: word
    input  [1:0]  MemRead_EM,
    input         DMSE_EM,          // 符号拡張制御（originと同じ）

    // data
    input  [31:0] ALU_VAL_EM,       // アドレス（EXの結果: ALU/SHIFT MUX後）
    input  [31:0] STORE_VAL_EM,     // 書き込みデータ（rs2のフォワード後）

    // output to WB
    output [31:0] MEM_DATA_M        // 読み出しデータ（アライン後）
);
    // Store 幅はデコード値をそのまま使用
    wire [1:0] DMWE = MemWrite_EM;
    wire [1:0] DMRE = MemRead_EM;

    // daligner ⇔ dmem 間の配線
    wire        CEM;
    wire [31:2] MADDR;
    wire [31:0] MDATAO;
    wire [31:0] MDATAI;
    wire [31:0] MDATAI_DMEM;
    wire [3:0]  MWSTB;

    // Data Aligner（origin と同じ役割）
    daligner daligner_inst (
        .CLK   (CLK),
        .ADDRI (ALU_VAL_EM),
        .DATAI (STORE_VAL_EM),
        .DATAO (MEM_DATA_M),
        .WE    (DMWE),
        .RE    (DMRE),
        .SE    (DMSE_EM),
        .MADDR (MADDR),
        .MDATAO(MDATAO),
        .MDATAI(MDATAI),
        .MWSTB (MWSTB)
    );

    // Data Memory Enable（origin と同じ判定）← CEMはそのまま
    assign CEM = ( ( |DMWE || |DMRE ) && (MADDR[31:20] == DMEM_BASE[31:20]) );

    // dmem からの読み出しを daligner に戻す
    assign MDATAI = MDATAI_DMEM;

    // Data Memory（origin と同じ I/F）
    dmem #(
        .DMEM_SIZE(DMEM_SIZE),
        .INIT_FILE(DMEM_FILE)
    ) dmem_inst (
        .CLK (CLK),
        .ADDR(MADDR),
        .DATAI(MDATAO),
        .DATAO(MDATAI_DMEM),
        .CE  (CEM),
        .WSTB(MWSTB)
    );
endmodule