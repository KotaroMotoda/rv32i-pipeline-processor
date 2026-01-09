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
    wire [4:0]  carry;   // per-byte carry chain (carry[4] is final cout)
    wire [3:0]  link_en; // carry enable per byte position
    wire [31:0] add_sum;

    assign is_sub = (C == `SUB)  | (C == `ISUB);

    // B' = B xor sub, cin = sub
    assign b_xor   = B ^ {32{is_sub}};
    assign carry[0] = is_sub;

    // Carry link enable: 1 allows carry to flow to next byte; 0 cuts and injects sub as new cin
    // link_en[0]: byte0->byte1, link_en[1]: byte1->byte2, link_en[2]: byte2->byte3, link_en[3]: byte3 final cout
    assign link_en = (P == 2'b10) ? 4'b1000 : // byte: cut all inter-byte carries
                     (P == 2'b00) ? 4'b1101 : // halfword: cut between lower and upper half
                                      4'b1111; // word (11 or 01): no cut

    genvar bi;
    generate
        for (bi = 0; bi < 4; bi = bi + 1) begin : ADDER_BYTE
            wire cout_raw;
            assign {cout_raw, add_sum[8*bi +: 8]} = A[8*bi +: 8] + b_xor[8*bi +: 8] + carry[bi];
            assign carry[bi+1] = link_en[bi] ? cout_raw : is_sub;
        end
    endgenerate

    // Operation results ---------------------------------------------------
    wire [32:0] add_res;
    wire [32:0] and_res;
    wire [32:0] or_res;
    wire [32:0] xor_res;
    reg  [32:0] X; // selected result (33-bit to keep carry)

    assign add_res = {carry[4], add_sum};
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
    assign overflowFlag = ((P == 2'b11) || (P == 2'b01)) ? (is_sub ? ((A[31] ^ B[31]) & (A[31] ^ add_sum[31]))
                                                           : (~(A[31] ^ B[31]) & (A[31] ^ add_sum[31])))
                                                         : 1'b0;
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
