`include "riscv.vh"

module riscv #(
    parameter DMEM_BASE = 32'h0010_0000,
    parameter DMEM_SIZE = 32768,
    parameter DMEM_FILE = "data.mif",
    parameter LED_BASE  = 32'h0012_0000  // 0x0011_FFFF より上
)(
    input  wire        CLK, // 100MHzで入ってくる想定
    input  wire        RSTN_IN,
    output wire [15:0] LED    
);
    wire CLK75;
    wire LOCKED;
    // 100MHz -> 75MHz に,周波数を落とす
    clk_wiz_0 clk_wiz_inst (
        .clk_in1( CLK ),
        .clk_out1( CLK75 ),
        .reset( ~RSTN_IN ),
        .locked(LOCKED)
    );

    assign RSTN    = RSTN_IN & LOCKED;
    wire RST = ~RSTN;

    // コア ⇔ トップ（MEMバス）
    wire [31:0] ALU_VAL_EM;     // アドレス（E段計算結果）
    wire [31:0] STORE_VAL_EM;   // ストアデータ（rs2）
    wire [1:0]  MemWrite_EM;    // 00:none,01:byte,10:half,11:word
    wire [1:0]  MemRead_EM;     // 00:none,01:byte,10:half,11:word
    wire        DMSE_EM;        // 符号拡張
    wire [31:0] MEM_DATA_M;     // ロードデータ（アライン後）→ コアへ

    // daligner ⇔ dmem/LED
    wire [31:2] MADDR;          // ワードアドレス
    wire [31:0] MDATAO;         // 書き込みデータ（バイト選択後）
    wire [31:0] MDATAI;         // 読み込みデータ（dmem/LEDから）
    wire [31:0] MDATAI_DMEM;    // dmem からの読み出し
    wire [3:0]  MWSTB;          // バイト書き込みストローブ
    wire        CEM;            // dmem CE（origin式のまま）
    reg  [31:0] led_reg;        // LED レジスタ

    // コア本体
    riscv_core core (
        .CLK(CLK75),
        .RSTN(RSTN),
        // MEMバス（コア→トップ）
        .ALU_VAL_EM(ALU_VAL_EM),
        .STORE_VAL_EM(STORE_VAL_EM),
        .MemWrite_EM(MemWrite_EM),
        .MemRead_EM(MemRead_EM),
        .DMSE_EM(DMSE_EM),
        // MEMバス（トップ→コア）
        .MEM_DATA_M(MEM_DATA_M)
    );

    // Data Aligner（origin と同じ）
    daligner daligner_inst (
        .CLK   (CLK75),
        .ADDRI (ALU_VAL_EM),
        .DATAI (STORE_VAL_EM),
        .DATAO (MEM_DATA_M),     // アライン／符号拡張済みデータをコアへ返す
        .WE    (MemWrite_EM),
        .RE    (MemRead_EM),
        .SE    (DMSE_EM),
        .MADDR (MADDR),
        .MDATAO(MDATAO),
        .MDATAI(MDATAI),
        .MWSTB (MWSTB)
    );

    // Data Memory Enable
    assign CEM = ( ( |MemWrite_EM || |MemRead_EM ) && (MADDR[31:20] == DMEM_BASE[31:20]) );

    // LED MMIO デコード（0x0011_FFFF より上）
    wire is_led_access = ( |MemWrite_EM || |MemRead_EM ) && ( {MADDR, 2'b00} >= LED_BASE );
    assign LED = led_reg[15:0];

    // LED 書き込み（MWSTBに従ってバイト単位更新）
    always @(posedge CLK75 or posedge RST) begin
        if (RST) begin
            led_reg <= 32'h0000_0000;
        end else if (is_led_access && |MemWrite_EM) begin
            if (MWSTB[0]) led_reg[7:0]   <= MDATAO[7:0];
            if (MWSTB[1]) led_reg[15:8]  <= MDATAO[15:8];
            if (MWSTB[2]) led_reg[23:16] <= MDATAO[23:16];
            if (MWSTB[3]) led_reg[31:24] <= MDATAO[31:24];
        end
    end

    // dmem
    dmem #(
        .DMEM_SIZE(DMEM_SIZE),
        .INIT_FILE(DMEM_FILE)
    ) dmem_inst (
        .CLK (CLK75),
        .ADDR(MADDR),
        .DATAI(MDATAO),
        .DATAO(MDATAI_DMEM),
        .CE  (CEM),
        .WSTB(MWSTB)
    );

    // 読み出し多重化：LED優先（LED空間に Read が来たら LED を返す）
    assign MDATAI = is_led_access ? led_reg : MDATAI_DMEM;
endmodule