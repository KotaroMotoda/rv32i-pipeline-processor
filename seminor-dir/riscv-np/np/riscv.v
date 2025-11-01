module riscv
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
    wire [31:0] PC4_IF;

    if_stage if_stage_inst (
        .CLK(CLK),
        .RST(RST),
        .PC_IF(PC_IF),
        .IDATA_IF(IDATA_IF),
        .PC4_IF(PC4_IF)
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
        .IDATA_IF(IDATA_IF),
        .IR(IR),
        .RF_DATA1(RF_DATA1),
        .RF_DATA2(RF_DATA2),
        .RD_ID(RD_ID),
        .RegWrite_ID(RegWrite_ID)
    );

    // EX stage
    wire [31:0] RD_VAL_E;

    ex_stage ex_stage_inst (
        .CLK(CLK),
        .RF_DATA1(RF_DATA1),
        .RF_DATA2(RF_DATA2),
        .RD_VAL_E(RD_VAL_E)
    );

    // MEM stage
    wire [31:0] MEM_DATA_M;

    mem_stage mem_stage_inst (
        .CLK(CLK),
        .RD_VAL_E(RD_VAL_E),
        .MEM_DATA_M(MEM_DATA_M)
    );

    // WB stage
    always @(posedge CLK) begin
        if (RegWrite_ID) begin
            WE_RD_VAL <= MEM_DATA_M;
        end
    end

endmodule