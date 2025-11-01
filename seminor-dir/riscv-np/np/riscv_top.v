module riscv_top
    (
        input CLK,
        input RSTN,
        output reg [31:0] WE_RD_VAL
    );

    wire RST;
    assign RST = ~RSTN;

    // Pipeline stage wires
    wire [31:0] PC_IF, IDATA_IF;
    wire [31:0] PC4_IF, PC_FD, IDATA_FD;
    wire [31:0] PC_DE, RF_DATA1_DE, RF_DATA2_DE, IMM_VAL_DE;
    wire [31:0] RD_VAL_E, DATA1_MUX_E, DATA2_MUX_E;
    wire [31:0] MEM_DATA_M;
    wire [31:0] RD_VAL_WB;
    wire [4:0] RD_DE, RD_MW;
    wire RegWrite_DE, RegWrite_MW;
    wire [1:0] MemtoReg_DE, MemtoReg_MW;

    // Instantiate pipeline registers
    pipeline_regs pipeline_regs_inst (
        .CLK(CLK),
        .RST(RST),
        .PC_IF(PC_IF),
        .IDATA_IF(IDATA_IF),
        .PC_DE(PC_DE),
        .RF_DATA1_DE(RF_DATA1_DE),
        .RF_DATA2_DE(RF_DATA2_DE),
        .IMM_VAL_DE(IMM_VAL_DE),
        .RD_VAL_E(RD_VAL_E),
        .RD_DE(RD_DE),
        .RD_MW(RD_MW),
        .RegWrite_DE(RegWrite_DE),
        .RegWrite_MW(RegWrite_MW),
        .MemtoReg_DE(MemtoReg_DE),
        .MemtoReg_MW(MemtoReg_MW)
    );

    // Instantiate IF stage
    if_stage if_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .PC_IF(PC_IF),
        .IDATA_IF(IDATA_IF)
    );

    // Instantiate ID stage
    id_stage id_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .PC_DE(PC_DE),
        .RF_DATA1_DE(RF_DATA1_DE),
        .RF_DATA2_DE(RF_DATA2_DE),
        .IMM_VAL_DE(IMM_VAL_DE),
        .RD_DE(RD_DE),
        .RegWrite_DE(RegWrite_DE),
        .MemtoReg_DE(MemtoReg_DE)
    );

    // Instantiate EX stage
    ex_stage ex_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .DATA1_MUX_E(DATA1_MUX_E),
        .DATA2_MUX_E(DATA2_MUX_E),
        .RD_VAL_E(RD_VAL_E)
    );

    // Instantiate MEM stage
    mem_stage mem_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .RD_VAL_E(RD_VAL_E),
        .MEM_DATA_M(MEM_DATA_M)
    );

    // Instantiate WB stage
    wb_stage wb_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .MEM_DATA_M(MEM_DATA_M),
        .RD_VAL_WB(RD_VAL_WB),
        .RD_MW(RD_MW),
        .RegWrite_MW(RegWrite_MW)
    );

    // Output assignment
    always @(posedge CLK) begin
        WE_RD_VAL <= RD_VAL_WB;
    end

endmodule