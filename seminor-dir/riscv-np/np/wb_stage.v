module wb_stage (
    input CLK,
    input RST,
    input [31:0] MEM_DATA_MW,
    input [31:0] PC4_MW,
    input [4:0] RD_MW,
    input [1:0] MemtoReg_MW,
    input RegWrite_MW,
    output reg [31:0] RD_VAL_WB,
    output reg [4:0] RD_WB
);

    always @(*) begin
        case (MemtoReg_MW)
            2'b01: RD_VAL_WB = MEM_DATA_MW; // Load data from memory
            2'b10: RD_VAL_WB = PC4_MW;     // Write back PC+4 for JAL/JALR
            default: RD_VAL_WB = RD_VAL_WB; // ALU result
        endcase
    end

    always @(posedge CLK or posedge RST) begin
        if (RST) begin
            RD_WB <= 5'b00000; // Reset register address
        end else begin
            RD_WB <= RD_MW; // Update register address for write back
        end
    end

endmodule