module daligner (
    input CLK,
    input RSTN,
    output reg [31:0] WE_RD_VAL
);

    // IF stage
    wire [31:0] PC_IF;
    wire [31:0] IDATA_IF;
    wire [31:0] PC4_IF;

    // ID stage
    wire [31:0] IR;
    wire [31:0] RF_DATA1;
    wire [31:0] RF_DATA2;
    wire [4:0] RD_ID;

    // EX stage
    wire [31:0] RD_VAL_E;

    // MEM stage
    wire [31:0] MEM_DATA_M;

    // WB stage
    wire [31:0] RD_VAL_WB;

    // Instantiate IF stage
    if_stage if_stage_inst (
        .CLK(CLK),
        .RSTN(RSTN),
        .PC_IF(PC_IF),
        .IDATA_IF(IDATA_IF),
        .PC4_IF(PC4_IF)
    );

    // Instantiate ID stage
    id_stage id_stage_inst (
        .CLK(CLK),
        .RSTN(RSTN),
        .IR(IR),
        .RF_DATA1(RF_DATA1),
        .RF_DATA2(RF_DATA2),
        .RD_ID(RD_ID)
    );

    // Instantiate EX stage
    ex_stage ex_stage_inst (
        .CLK(CLK),
        .RF_DATA1(RF_DATA1),
        .RF_DATA2(RF_DATA2),
        .RD_VAL_E(RD_VAL_E)
    );

    // Instantiate MEM stage
    mem_stage mem_stage_inst (
        .CLK(CLK),
        .RD_VAL_E(RD_VAL_E),
        .MEM_DATA_M(MEM_DATA_M)
    );

    // Instantiate WB stage
    wb_stage wb_stage_inst (
        .CLK(CLK),
        .MEM_DATA_M(MEM_DATA_M),
        .RD_VAL_WB(RD_VAL_WB)
    );

    // Output assignment
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN)
            WE_RD_VAL <= 32'b0;
        else
            WE_RD_VAL <= RD_VAL_WB;
    end

endmodule