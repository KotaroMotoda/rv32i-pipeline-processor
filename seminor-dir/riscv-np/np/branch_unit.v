module branch_unit (
    input wire [31:0] PC,
    input wire [31:0] IMM,
    input wire isBranch,
    output reg [31:0] nextPC
);

    always @(*) begin
        if (isBranch) begin
            nextPC = PC + IMM; // Update PC for branch instruction
        end else begin
            nextPC = PC + 4; // Default next PC
        end
    end

endmodule