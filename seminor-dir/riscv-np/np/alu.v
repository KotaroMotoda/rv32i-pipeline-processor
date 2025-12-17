`include "alu.vh"

// ALU with P-mode split carry adder
module alu ( A, B, C, P, Y );
    input [31:0] A;
    input [31:0] B;
    input [4:0]  C;
    input [1:0]  P; // PACK SIZE. 11: word, 10: byte, 00: halfword (01 is treated as word)
    output [31:0] Y;
    reg [31:0] Y;

    // Split-carry ripple adder --------------------------------------------
    wire is_sub;
    wire [31:0] b_xor;
    wire [32:0] carry;
    wire [31:0] link_en; // carry enable per bit position
    wire [31:0] add_sum;

    assign is_sub = (C == `SUB)  | (C == `ISUB);

    // B' = B xor sub, cin = sub
    assign b_xor   = B ^ {32{is_sub}};
    assign carry[0] = is_sub;

    // Carry link enable: 1 allows carry to flow to next bit; 0 cuts and injects sub as new cin
    assign link_en = (P == 2'b10) ? 32'hFF7F7F7F : // byte: cut at bits 7,15,23
                     (P == 2'b00) ? 32'hFFFF7FFF : // halfword: cut at bit 15
                                      32'hFFFFFFFF; // word (11 or 01): no cut

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : ADDER
            wire cout_raw;
            assign {cout_raw, add_sum[i]} = A[i] + b_xor[i] + carry[i];
            assign carry[i+1] = link_en[i] ? cout_raw : is_sub;
        end
    endgenerate

    // Operation results ---------------------------------------------------
    wire [32:0] add_res;
    wire [32:0] and_res;
    wire [32:0] or_res;
    wire [32:0] xor_res;
    reg  [32:0] X; // selected result (33-bit to keep carry)

    assign add_res = {carry[32], add_sum};
    assign and_res = {1'b0, A & B};
    assign or_res  = {1'b0, A | B};
    assign xor_res = {1'b0, A ^ B};

    always @* begin
        case (C)
            `ADD, `SUB, `IADD, `ISUB: X = add_res;
            `IAND: X = and_res;
            `IOR : X = or_res;
            `IXOR: X = xor_res;
            default: X = add_res; // fallback to add/sub path
        endcase
    end

    // Flags ---------------------------------------------------------------
    wire overflowFlag; // overflow flag
    wire zeroFlag; // zero flag
    wire lessThanUnsignedFlag; // less than unsigned flag
    wire lessThanFlag; // less than flag

    // For Pモード（8/16bit分割）ではオーバーフローを無効化。ワード時のみ従来のOFを計算。
    assign overflowFlag = ((P == 2'b11) || (P == 2'b01)) ? (carry[31] ^ carry[32]) : 1'b0;
    assign zeroFlag = (X[31:0] == 32'b0);
    assign lessThanUnsignedFlag = (A < B);
    assign lessThanFlag = ($signed(A) < $signed(B));

    // Output MUX ----------------------------------------------------------
    always @* begin
        case( C )
            `lessThan             : Y = {31'b0, lessThanFlag};
            `lessThanUnsigned     : Y = {31'b0, lessThanUnsignedFlag};
            `greaterEqual         : Y = {31'b0, ~lessThanFlag};
            `greaterEqualUnsigned : Y = {31'b0, ~lessThanUnsignedFlag};
            `equal                : Y = {31'b0, zeroFlag};
            `notEqual             : Y = {31'b0, ~zeroFlag};
            default               : Y = X[31:0];
        endcase
    end
endmodule
