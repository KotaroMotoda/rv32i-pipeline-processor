`include "riscv.vh"
`include "inst.vh"
`include "alu.vh"
`define LITTLE_ENDIAN


module riscv
    #(
        parameter IMEM_BASE = 32'h0000_0000,
        parameter IMEM_SIZE = 32768,	// 32kW = 128kB
        parameter IMEM_FILE = "prog.mif",
        parameter DMEM_BASE = 32'h0010_0000,
        parameter DMEM_SIZE = 32768,	// 32kW = 128kB
        parameter DMEM_FILE = "data.mif"
    )
    (
        input CLK,
        input RSTN,
        output reg [31:0] WE_RD_VAL
    );

    wire RST;
    assign RST = ~RSTN;

    //========================================
    // 命令メモリ(IM)定義 32bit
    //========================================
    reg [31:0] imem[0:IMEM_SIZE-1];

    initial
    begin
        $readmemh( IMEM_FILE, imem );
    end

    //========================================
    // IF段の信号
    //========================================
    reg [31:0] PC_IF;
    wire [31:0] PC4_IF;
    wire [31:0] IDATA_IF;

    //========================================
    // IF/IDパイプラインレジスタ
    //========================================
    reg [31:0] PC_FD;
    reg [31:0] IDATA_FD;
    reg [31:0] PC4_FD;

    //========================================
    // ID段の信号
    //========================================
    wire [31:0] IR;
    reg [4:0] IALU_ID;
    wire [31:0] RF_DATA1;
    wire [31:0] RF_DATA2;
    reg [4:0] RD_ID;

    //========================================
    // ID/EXパイプラインレジスタ
    //========================================
    reg [31:0] PC_DE;
    reg [31:0] RF_DATA1_DE;
    reg [31:0] RF_DATA2_DE;
    reg [4:0] IALU_DE;
    reg [4:0] RD_DE;

    //========================================
    // EX段の信号
    //========================================
    wire [31:0] RD_VAL_E;

    //========================================
    // EX/MEMパイプラインレジスタ
    //========================================
    reg [31:0] PC_EM;
    reg [31:0] RD_VAL_EM;
    reg [4:0] RD_EM;

    //========================================
    // MEM/WBパイプラインレジスタ
    //========================================
    reg [31:0] PC_MW;
    reg [31:0] RD_VAL_MW;
    reg [4:0] RD_MW;

    //========================================
    // IF段の処理
    //========================================
    assign PC4_IF = PC_IF + 4;
    
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
            PC_IF <= 32'h00000000;
        else
            PC_IF <= PC4_IF;
    end	

    assign IDATA_IF = imem[PC_IF[31:2]];

    //========================================
    // IF/IDパイプラインレジスタ更新
    //========================================
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            PC_FD <= 32'h00000000;
            PC4_FD <= 32'h00000004;
            IDATA_FD <= 32'h00000000;
        end
        else
        begin
            PC_FD <= PC_IF;
            PC4_FD <= PC4_IF;
            IDATA_FD <= IDATA_IF;
        end
    end

    //========================================
    // エンディアン変換（組み合わせ論理）
    //========================================
    `ifdef BIG_ENDIAN
    assign IR = IDATA_FD;
    `endif
    `ifdef LITTLE_ENDIAN
    assign IR = {IDATA_FD[7:0], IDATA_FD[15:8], IDATA_FD[23:16], IDATA_FD[31:24]};
    `endif

    //========================================
    // ID段の処理（組み合わせ論理）
    //========================================
    always @(*)
    begin
        case (`IR_F7)
            7'b0100000: IALU_ID = `SUB;
            default:    IALU_ID = `ADD;
        endcase
        RD_ID = `IR_RD;
    end

    //========================================
    // レジスタファイル
    //========================================
    rf rf_inst(
        .CLK(CLK),
        .RNUM1(`IR_RS1), .RDATA1(RF_DATA1),
        .RNUM2(`IR_RS2), .RDATA2(RF_DATA2),
        .WNUM(RD_MW),    .WDATA(RD_VAL_MW)
    );

    //========================================
    // ID/EXパイプラインレジスタ更新
    //========================================
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            PC_DE <= 32'h00000000;
            RF_DATA1_DE <= 32'h00000000;
            RF_DATA2_DE <= 32'h00000000;
            IALU_DE <= 5'b00000;
            RD_DE <= 5'b00000;
        end
        else
        begin
            PC_DE <= PC_FD;
            RF_DATA1_DE <= RF_DATA1;
            RF_DATA2_DE <= RF_DATA2;
            IALU_DE <= IALU_ID;
            RD_DE <= RD_ID;
        end
    end

    //========================================
    // EX段の処理（ALU）
    //========================================
    alu alu_inst(
        .A(RF_DATA1_DE), 
        .B(RF_DATA2_DE), 
        .C(IALU_DE), 
        .Y(RD_VAL_E)
    );

    //========================================
    // EX/MEMパイプラインレジスタ更新
    //========================================
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            PC_EM <= 32'h00000000;
            RD_VAL_EM <= 32'h00000000;
            RD_EM <= 5'b00000;
        end
        else
        begin
            PC_EM <= PC_DE;
            RD_VAL_EM <= RD_VAL_E;
            RD_EM <= RD_DE;
        end
    end

    //========================================
    // MEM/WBパイプラインレジスタ更新
    //========================================
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            PC_MW <= 32'h00000000;
            RD_VAL_MW <= 32'h00000000;
            RD_MW <= 5'b00000;
        end
        else
        begin
            PC_MW <= PC_EM;
            RD_VAL_MW <= RD_VAL_EM;
            RD_MW <= RD_EM;
        end
    end

    //========================================
    // デバッグ用出力
    //========================================
    always @(posedge CLK)
    begin
        WE_RD_VAL <= RD_VAL_MW;
    end

endmodule