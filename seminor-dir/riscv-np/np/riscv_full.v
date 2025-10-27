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

    // IM 
    reg [31:0] imem[0:IMEM_SIZE-1];

    initial
    begin
        $readmemh( IMEM_FILE, imem );
    end

    // IF reg
    reg [31:0] PC_IF;
    wire [31:0] PC4_IF;
    wire [31:0] IDATA_IF;

    // IF/ID pipeline reg
    reg [31:0] PC_FD;
    reg [31:0] IDATA_FD;
    reg [31:0] PC4_FD;

    // ID reg
    wire [31:0] IR;
    reg [4:0] IALU_ID;
    wire [31:0] RF_DATA1;
    wire [31:0] RF_DATA2;
    reg [4:0] RD_ID;
    reg [15:0] IMM_VAL_ID;
    reg [31:0] IMM_VAL_EXT_ID; // 符号拡張済みimm値
    reg [2:0] FT_ID; // 命令フォーマットタイプ
    
    // Control reg in ID
    reg [1:0] MemtoReg_ID;
    reg RegWrite_ID;
    reg [31:0] Branch_ID;
    reg [1:0] MemWrite_ID;
    reg [1:0] MemRead_ID;
    reg ALUSrc_ID;
    reg [1:0] ALUOp_ID;
    reg [1:0] ALUDst_ID;
    reg DMSE_ID; // 0: unsigned, 1: signed loadでしか用いない.
    reg ALUorSHIFT_ID; // 0: ALU, 1: SHIFT VAL_MUXの選択用
    reg RS1_PC_ID;
    reg RS1_Z_ID;
    reg PC_E_ID;

    // ID/EX pipeline reg
    reg [31:0] PC4_DE;
    reg [31:0] PC_DE;
    reg [31:0] RF_DATA1_DE;
    reg [31:0] RF_DATA2_DE;
    reg [4:0] IALU_DE;
    reg [31:0] IMM_VAL_DE;
    reg [4:0] RD_DE;
    // Control reg in ID/EX
    reg [1:0] MemtoReg_DE;
    reg RegWrite_DE;
    reg Branch_DE;
    reg [1:0] MemWrite_DE;
    reg [1:0] MemRead_DE;
    reg ALUSrc_DE;
    reg [1:0] ALUOp_DE;
    reg [1:0] ALUDst_DE;
    reg DMSE_DE; // 0: unsigned, 1: signed loadでしか用いない.
    reg ALUorSHIFT_DE; // 0: ALU, 1: SHIFT VAL_MUXの選択用
    reg [2:0] FT_DE; // 命令フォーマットタイプ

    // EX reg
    wire [31:0] RD_VAL_E;
    reg [31:0] IMM_VAL_SHIFT_E; // immを2bit左シフトした値
    reg [31:0] DATA1_MUX_E; // DATA1_MUXからのデータ
    reg [31:0] DATA2_MUX_E; // DATA2_MUXからのデータ
    reg [31:0] ALU_VAL_E; // ALUからの出力値
    reg [1:0] equalZero_E; // ALUからの出力値
    wire isBranch_E; // 分岐命令かどうかのフラグ
    reg [31:0] WA_E; // 書き込みアドレス
    reg [31:0] WD_E; // 書き込みデータ（WD_D → WD_E）
    reg [31:0] PC_IMM_E; // PC + IMM
    reg [31:0] IMM_VAL_E; // IDから渡されたimm値

    // EX/MEM pipeline reg
    
    reg [31:0] PC_EM;
    reg [31:0] PC4_EM;
    reg [31:0] WA_EM;
    reg [31:0] WD_EM;
    reg [31:0] RD_VAL_EM; // 追加
    reg [4:0] RD_EM;
    reg [2:0] FT_EM; // 命令フォーマットタイプ
    reg [4:0] IALU_EM;

    // Control reg in EX/MEM
    reg [1:0] MemtoReg_EM;
    reg RegWrite_EM;
    reg [1:0] MemWrite_EM;
    reg [1:0] MemRead_EM;
    reg DMSE_EM; // 0: unsigned, 1: signed loadでしか用いない.

    // MEM reg
    reg [31:0] MEM_DATA_M;
    reg [31:0] WA_M;
    reg [31:0] WD_M;

    // MEM/WB pipeline reg
    reg [31:0] PC_MW;
    reg [31:0] PC4_MW;
    reg [31:0] MEM_DATA_MW;
    reg [31:0] WA_MW;
    reg [31:0] RD_VAL_MW; // 追加
    reg [4:0] RD_MW;
    // Control reg in MEM/WB
    reg [1:0] MemtoReg_MW;
    reg RegWrite_MW;

    // WB reg
    reg [31:0] PC4_WB;
    reg [31:0] MEM_DATA_WB;
    reg [31:0] WA_WB;
    reg [31:0] WB_MUX;
 
    // IF stage
    assign PC4_IF = PC_IF + 4;
    
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
            PC_IF <= 32'h00000000;
        else if (isBranch_E)
            PC_IF <= PC_IMM_E;
        else
            PC_IF <= PC4_IF;
    end	

    assign IDATA_IF = imem[PC_IF[31:2]];

    // IF/ID pipeline reg update
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

    // define IR
    `ifdef BIG_ENDIAN
    assign IR = IDATA_FD;
    `endif
    `ifdef LITTLE_ENDIAN
    assign IR = {IDATA_FD[7:0], IDATA_FD[15:8], IDATA_FD[23:16], IDATA_FD[31:24]};
    `endif

    // ID stage
    // Instruction decoder
    always @(IR)
    begin
        FT_ID <= 3'b000; // default : undefined instruction
        IALU_ID <= `IADD;  // default operation
        MemtoReg_ID <= 2'b00;  // for R-type(00 for alu), I-type(01 for dmem), U-type(10 for PC+4)
        MemWrite_ID <= 2'b00;  // no store
        MemRead_ID <= 2'b00;  // no load
        DMSE_ID <= 1'b0;   // unsigned
        RS1_PC_ID <= 1'b0;   // no use PC for RS1
        RS1_Z_ID <= 1'b0;   // no use Zero for RS1 
        PC_E_ID <= 1'b0;   // no branch
        
        case(`IR_OP)
            `OP_LUI:
            begin 
                FT_ID <= `FT_U;
                RS1_Z_ID <= 1'b1;
            end
            `OP_AUIPC: 
            begin
                FT_ID <= `FT_U;
                RS1_PC_ID <= 1'b1;
            end
            `OP_JAL:
            begin
                FT_ID <= `FT_J;
                RS1_PC_ID <= 1'b1;
                PC_E_ID <= 1'b1; 
                MemtoReg_ID <= 2'b10;
            end
            `OP_JALR: 
            begin
                FT_ID <= `FT_I;
                PC_E_ID <= 1'b1; 
                MemtoReg_ID <= 2'b10;
            end
            `OP_BR: 
            begin
                FT_ID <= `FT_B;
                PC_E_ID <= 1'b1;
                case(`IR_F3)
                    3'b000: IALU_ID <= `IADD; // beq (仮にIADD、実際は比較演算)
                    3'b001: IALU_ID <= `ISUB; // bne
                    3'b100: IALU_ID <= `ISUB; // blt
                    3'b101: IALU_ID <= `IADD; // bge
                    3'b110: IALU_ID <= `ISUB; // bltu
                    3'b111: IALU_ID <= `IADD; // bgeu
                endcase
            end
            `OP_LOAD:
            begin
                FT_ID <= `FT_I;
                MemtoReg_ID <= 2'b01;
                case(`IR_F3)
                    3'b000: begin MemRead_ID <= 2'b01; DMSE_ID <= 1'b1; end // lb
                    3'b001: begin MemRead_ID <= 2'b10; DMSE_ID <= 1'b1; end // lh
                    3'b010: begin MemRead_ID <= 2'b11; DMSE_ID <= 1'b1; end // lw
                    3'b100: MemRead_ID <= 2'b01; // lbu
                    3'b101: MemRead_ID <= 2'b10; // lhu
                    3'b110: MemRead_ID <= 2'b11; // lwu
                endcase
            end
            `OP_STORE:
            begin
                FT_ID <= `FT_S;
                case(`IR_F3)
                    3'b000: MemWrite_ID <= 2'b01; // sb
                    3'b001: MemWrite_ID <= 2'b10; // sh
                    3'b010: MemWrite_ID <= 2'b11; // sw
                endcase
            end
            `OP_FUNC1: // Immediate
            begin
                FT_ID <= `FT_I;
                case(`IR_F3)
                    3'b000: IALU_ID <= `IADD; // addi
                    3'b001: if(`IR_F7 == 7'b0000000) IALU_ID <= `ISLL; // slli
                    3'b010: IALU_ID <= `IADD; // slti (仮にIADD)
                    3'b011: IALU_ID <= `IADD; // sltiu (仮にIADD)
                    3'b100: IALU_ID <= `IXOR; // xori
                    3'b101: begin
                        if(`IR_F7 == 7'b0000000) IALU_ID <= `ISRL; // srli
                        else if(`IR_F7 == 7'b0100000) IALU_ID <= `ISRA; // srai
                    end
                    3'b110: IALU_ID <= `IOR; // ori
                    3'b111: IALU_ID <= `IAND; // andi
                endcase
            end
            `OP_FUNC2: // R type
            begin
                FT_ID <= `FT_R;
                case(`IR_F3)
                    3'b000: begin
                        if(`IR_F7 == 7'b0000000) IALU_ID <= `IADD; // add
                        else if(`IR_F7 == 7'b0100000) IALU_ID <= `ISUB; // sub
                    end
                    3'b001: if(`IR_F7 == 7'b0000000) IALU_ID <= `ISLL; // sll
                    3'b010: if(`IR_F7 == 7'b0000000) IALU_ID <= `IADD; // slt (仮にIADD)
                    3'b011: if(`IR_F7 == 7'b0000000) IALU_ID <= `IADD; // sltu (仮にIADD)
                    3'b100: if(`IR_F7 == 7'b0000000) IALU_ID <= `IXOR; // xor
                    3'b101: begin
                        if(`IR_F7 == 7'b0000000) IALU_ID <= `ISRL; // srl
                        else if(`IR_F7 == 7'b0100000) IALU_ID <= `ISRA; // sra
                    end
                    3'b110: if(`IR_F7 == 7'b0000000) IALU_ID <= `IOR; // or
                    3'b111: if(`IR_F7 == 7'b0000000) IALU_ID <= `IAND; // and
                endcase
            end
        endcase
        
        RD_ID <= `IR_RD;
    end

    // rf
    rf rf_inst(
        .CLK(CLK),
        .RNUM1(`IR_RS1), .RDATA1(RF_DATA1),
        .RNUM2(`IR_RS2), .RDATA2(RF_DATA2),
        .WNUM(RD_MW),    .WDATA(RD_VAL_MW)
    );

    // ID/EX pipeline reg update
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            PC_DE <= 32'h00000000;
            PC4_DE <= 32'h00000000;
            RF_DATA1_DE <= 32'h00000000;
            RF_DATA2_DE <= 32'h00000000;
            IALU_DE <= 5'b00000;
            RD_DE <= 5'b00000;
        end
        else
        begin
            PC_DE <= PC_FD;
            PC4_DE <= PC4_FD;
            RF_DATA1_DE <= RF_DATA1;
            RF_DATA2_DE <= RF_DATA2;
            IALU_DE <= IALU_ID;
            RD_DE <= RD_ID;
        end
    end

    // EX stage
    alu alu_inst(
        .A(RF_DATA1_DE), 
        .B(RF_DATA2_DE), 
        .C(IALU_DE), 
        .Y(RD_VAL_E)
    );

    // EX/MEM pipeline reg update
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            PC_EM <= 32'h00000000;
            PC4_EM <= 32'h00000000;
            RD_VAL_EM <= 32'h00000000;
            RD_EM <= 5'b00000;
        end
        else
        begin
            PC_EM <= PC_DE;
            PC4_EM <= PC4_DE;
            RD_VAL_EM <= RD_VAL_E;
            RD_EM <= RD_DE;
        end
    end

    // MEM/WB pipeline reg update
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            PC_MW <= 32'h00000000;
            PC4_MW <= 32'h00000000;
            RD_VAL_MW <= 32'h00000000;
            RD_MW <= 5'b00000;
        end
        else
        begin
            PC_MW <= PC_EM;
            PC4_MW <= PC4_EM;
            RD_VAL_MW <= RD_VAL_EM;
            RD_MW <= RD_EM;
        end
    end

    // isBranch_E の定義を追加（仮実装）
    assign isBranch_E = 1'b0; // 実際の分岐判定ロジックを実装する必要がある

    // define output
    always @(posedge CLK)
    begin
        WE_RD_VAL <= RD_VAL_MW;
    end

endmodule