`include "alu.vh"
module alu ( A, B, C, Y );
    input [31:0] A;
    input [31:0] B;
    input [4:0] C;
    output [31:0] Y;
    reg [31:0] Y;

    reg [32:0] X; // 33bitで計算（オーバーフロー検出のため）

    wire overflowFlag; // overflow flag
    wire zeroFlag; // zero flag
    wire lessThanUnsignedFlag; // less than unsigned flag
    wire lessThanFlag; // less than flag


    always @( A or B or C )
        begin
            case( C )
                `ADD : X <= { 1'b0, A } + { 1'b0, B };
                `SUB : X <= { 1'b0, A } - { 1'b0, B };
                `IADD : X <= { 1'b0, A } + { 1'b0, B };
                `IAND : X <= { 1'b0, A } & { 1'b0, B };
                `IOR  : X <= { 1'b0, A } | { 1'b0, B };
                `IXOR : X <= { 1'b0, A } ^ { 1'b0, B };
                default: X <= { 1'b0, A } - { 1'b0, B };
            endcase
        end

    // Flags
    assign overflowFlag = ((A[31] & ~B[31] & ~X[31]) | (~A[31] & B[31] & X[31]));
    assign zeroFlag = (X[31:0] == 32'b0);                         
    assign lessThanUnsignedFlag = (A < B);                    
    assign lessThanFlag = ($signed(A) < $signed(B));      

    // Output MUX
    always @( overflowFlag or zeroFlag or lessThanUnsignedFlag or lessThanFlag or X or C )
        begin
            case( C )
                `lessThan             : Y <= {31'b0, lessThanFlag};
                `lessThanUnsigned     : Y <= {31'b0, lessThanUnsignedFlag};
                `greaterEqual         : Y <= {31'b0, ~lessThanFlag};
                `greaterEqualUnsigned : Y <= {31'b0, ~lessThanUnsignedFlag};
                `equal                : Y <= {31'b0, zeroFlag};
                `notEqual             : Y <= {31'b0, ~zeroFlag};
                default               : Y <= X[31:0];
            endcase
        end
endmodule
