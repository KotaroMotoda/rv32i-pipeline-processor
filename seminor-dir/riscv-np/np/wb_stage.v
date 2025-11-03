module wb_stage (
    input  [1:0]  MemtoReg_MW,
    input  [31:0] MEM_DATA_MW,
    input  [31:0] PC4_MW,
    input  [31:0] RD_VAL_MW,
    output reg [31:0] RD_VAL_WB
);
    always @(*) begin
        case (MemtoReg_MW)
            2'b01: RD_VAL_WB = MEM_DATA_MW; // Load
            2'b10: RD_VAL_WB = PC4_MW;      // jal/jalr
            default: RD_VAL_WB = RD_VAL_MW; // ALU/Shifter
        endcase
    end
endmodule