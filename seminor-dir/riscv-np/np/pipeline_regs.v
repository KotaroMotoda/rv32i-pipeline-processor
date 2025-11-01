module pipeline_regs (
    input  CLK,
    input  RST,

    // IF -> ID
    input  [31:0] PC_IF,
    input  [31:0] IDATA_IF,
    input  [31:0] PC4_IF,
    output reg [31:0] PC_FD,
    output reg [31:0] IDATA_FD,
    output reg [31:0] PC4_FD,

    // ID stage values to latch
    input  [31:0] RF_DATA1,
    input  [31:0] RF_DATA2,
    input  [4:0]  IALU_ID,
    input  [4:0]  RD_ID,
    input  [31:0] IMM_VAL_EXT_ID,
    input         ALUSrc_ID,
    input  [2:0]  FT_ID,
    input         RS1_PC_ID,
    input         RS1_Z_ID,
    input  [1:0]  MemtoReg_ID,
    input         RegWrite_ID,

    // ID -> EX
    output reg [31:0] PC_DE,
    output reg [31:0] PC4_DE,
    output reg [31:0] RF_DATA1_DE,
    output reg [31:0] RF_DATA2_DE,
    output reg [4:0]  IALU_DE,
    output reg [31:0] IMM_VAL_DE,
    output reg [4:0]  RD_DE,
    output reg        RS1_PC_DE,
    output reg        RS1_Z_DE,
    output reg [1:0]  MemtoReg_DE,
    output reg        RegWrite_DE,
    output reg        ALUSrc_DE,
    output reg [2:0]  FT_DE,

    // EX stage values to latch into EX/MEM
    input  [31:0] RD_VAL_E,

    // EX -> MEM
    output reg [31:0] PC4_EM,
    output reg [31:0] RD_VAL_EM,
    output reg [4:0]  RD_EM,
    output reg [1:0]  MemtoReg_EM,
    output reg        RegWrite_EM,

    // MEM -> WB
    output reg [31:0] PC4_MW,
    output reg [31:0] RD_VAL_MW,
    output reg [4:0]  RD_MW,
    output reg [1:0]  MemtoReg_MW,
    output reg        RegWrite_MW
);
    // IF/ID
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            PC_FD    <= 32'h0000_0000;
            PC4_FD   <= 32'h0000_0004;
            IDATA_FD <= 32'h0000_0000;
        end else begin
            PC_FD    <= PC_IF;
            PC4_FD   <= PC4_IF;
            IDATA_FD <= IDATA_IF;
        end
    end

    // ID/EX
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            PC_DE        <= 32'h0000_0000;
            PC4_DE       <= 32'h0000_0000;
            RF_DATA1_DE  <= 32'h0000_0000;
            RF_DATA2_DE  <= 32'h0000_0000;
            IALU_DE      <= 5'b00000;
            RD_DE        <= 5'b00000;
            MemtoReg_DE  <= 2'b00;
            RegWrite_DE  <= 1'b0;
            ALUSrc_DE    <= 1'b0;
            FT_DE        <= 3'b000;
            RS1_PC_DE    <= 1'b0;
            RS1_Z_DE     <= 1'b0;
            IMM_VAL_DE   <= 32'h0000_0000;
        end else begin
            PC_DE        <= PC_FD;
            PC4_DE       <= PC4_FD;
            RF_DATA1_DE  <= RF_DATA1;
            RF_DATA2_DE  <= RF_DATA2;
            IALU_DE      <= IALU_ID;
            RD_DE        <= RD_ID;
            IMM_VAL_DE   <= IMM_VAL_EXT_ID;
            ALUSrc_DE    <= ALUSrc_ID;
            FT_DE        <= FT_ID;
            RS1_PC_DE    <= RS1_PC_ID;
            RS1_Z_DE     <= RS1_Z_ID;
            MemtoReg_DE  <= MemtoReg_ID;
            RegWrite_DE  <= RegWrite_ID;
        end
    end

    // EX/MEM
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            PC4_EM      <= 32'h0000_0000;
            RD_VAL_EM   <= 32'h0000_0000;
            RD_EM       <= 5'b00000;
            MemtoReg_EM <= 2'b00;
            RegWrite_EM <= 1'b0;
        end else begin
            PC4_EM      <= PC4_DE;
            RD_VAL_EM   <= RD_VAL_E;
            RD_EM       <= RD_DE;
            MemtoReg_EM <= MemtoReg_DE;
            RegWrite_EM <= RegWrite_DE;
        end
    end

    // MEM/WB
    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            PC4_MW      <= 32'h0000_0000;
            RD_VAL_MW   <= 32'h0000_0000;
            RD_MW       <= 5'b00000;
            MemtoReg_MW <= 2'b00;
            RegWrite_MW <= 1'b0;
        end else begin
            PC4_MW      <= PC4_EM;
            RD_VAL_MW   <= RD_VAL_EM;
            RD_MW       <= RD_EM;
            MemtoReg_MW <= MemtoReg_EM;
            RegWrite_MW <= RegWrite_EM;
        end
    end

endmodule