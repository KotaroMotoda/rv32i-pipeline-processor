module riscv_origin
    (
        input CLK,
        input RSTN,
        output reg [31:0] WE_RD_VAL
    );

    wire RST;
    assign RST = ~RSTN;

    // IF stage
    wire [31:0] PC_IF;
    wire [31:0] IDATA_IF;

    if_stage if_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .PC(PC_IF),
        .IDATA(IDATA_IF)
    );

    // ID stage
    wire [31:0] IR;
    wire [31:0] RF_DATA1;
    wire [31:0] RF_DATA2;
    wire [4:0] RD_ID;
    wire RegWrite_ID;

    id_stage id_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .IDATA(IDATA_IF),
        .IR(IR),
        .RF_DATA1(RF_DATA1),
        .RF_DATA2(RF_DATA2),
        .RD_ID(RD_ID),
        .RegWrite(RegWrite_ID)
    );

    // EX stage
    wire [31:0] RD_VAL_E;

    ex_stage ex_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .RF_DATA1(RF_DATA1),
        .RF_DATA2(RF_DATA2),
        .RD_VAL_E(RD_VAL_E)
    );

    // MEM stage
    wire [31:0] MEM_DATA_M;

    mem_stage mem_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .RD_VAL_E(RD_VAL_E),
        .MEM_DATA(MEM_DATA_M)
    );

    // WB stage
    wb_stage wb_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .MEM_DATA(MEM_DATA_M),
        .WE_RD_VAL(WE_RD_VAL),
        .RegWrite(RegWrite_ID)
    );

endmodule