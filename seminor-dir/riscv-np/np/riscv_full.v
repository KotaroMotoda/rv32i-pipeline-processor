module riscv_full
    (
        input CLK,
        input RSTN,
        output reg [31:0] WE_RD_VAL
    );

    wire [31:0] PC_IF;
    wire [31:0] IDATA_IF;
    wire [31:0] PC4_IF;

    wire [31:0] PC_FD;
    wire [31:0] IDATA_FD;
    wire [31:0] PC4_FD;

    wire [31:0] IR;
    wire [31:0] RF_DATA1;
    wire [31:0] RF_DATA2;
    wire [31:0] IMM_VAL_DE;
    wire [31:0] RD_VAL_E;
    wire [31:0] MEM_DATA_M;
    wire [31:0] RD_VAL_MW;

    // Instantiate pipeline registers
    pipeline_regs pipeline_regs_inst(
        .CLK(CLK),
        .RSTN(RSTN),
        .PC_IF(PC_IF),
        .IDATA_IF(IDATA_IF),
        .PC4_IF(PC4_IF),
        .PC_FD(PC_FD),
        .IDATA_FD(IDATA_FD),
        .PC4_FD(PC4_FD),
        .IR(IR),
        .RF_DATA1(RF_DATA1),
        .RF_DATA2(RF_DATA2),
        .IMM_VAL_DE(IMM_VAL_DE),
        .RD_VAL_E(RD_VAL_E),
        .MEM_DATA_M(MEM_DATA_M),
        .RD_VAL_MW(RD_VAL_MW)
    );

    // Instantiate IF stage
    if_stage if_stage_inst(
        .CLK(CLK),
        .RSTN(RSTN),
        .PC_IF(PC_IF),
        .IDATA_IF(IDATA_IF),
        .PC4_IF(PC4_IF)
    );

    // Instantiate ID stage
    id_stage id_stage_inst(
        .CLK(CLK),
        .RSTN(RSTN),
        .IR(IR),
        .RF_DATA1(RF_DATA1),
        .RF_DATA2(RF_DATA2),
        .IMM_VAL_DE(IMM_VAL_DE)
    );

    // Instantiate EX stage
    ex_stage ex_stage_inst(
        .CLK(CLK),
        .RF_DATA1(RF_DATA1),
        .RF_DATA2(RF_DATA2),
        .IMM_VAL_DE(IMM_VAL_DE),
        .RD_VAL_E(RD_VAL_E)
    );

    // Instantiate MEM stage
    mem_stage mem_stage_inst(
        .CLK(CLK),
        .RD_VAL_E(RD_VAL_E),
        .MEM_DATA_M(MEM_DATA_M)
    );

    // Instantiate WB stage
    wb_stage wb_stage_inst(
        .MEM_DATA_M(MEM_DATA_M),
        .RD_VAL_MW(RD_VAL_MW)
    );

    // Define output
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN)
            WE_RD_VAL <= 32'b0;
        else
            WE_RD_VAL <= RD_VAL_MW;
    end

endmodule