// filepath: /Users/motodakoutaroukari/Documents/workspace/github.com/KotaroMotoda/rv32i-pipeline-processor/seminor-dir/riscv-np/np/alu.v
module alu (
    input [31:0] A,
    input [31:0] B,
    input [1:0] ALUOp,
    output reg [31:0] Y
);

    always @(*) begin
        case (ALUOp)
            2'b00: Y = A + B; // ADD
            2'b01: Y = A - B; // SUB
            2'b10: Y = A & B; // AND
            2'b11: Y = A | B; // OR
            default: Y = 32'b0; // Default case
        endcase
    end

endmodule