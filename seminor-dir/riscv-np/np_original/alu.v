`include "alu.vh"

// 8bitずつ分割するALUモジュール
// module alu ( A, B, C, P, Y );
//     input [31:0] A;
//     input [31:0] B;
//     input [4:0]  C;
//     input [1:0]  P; // PACK SIZE. 11: word, 10: byte, 00: halfword (01 is treated as word)
//     output [31:0] Y;
//     reg [31:0] Y;

//     // 8bitずつ分割して加減算を行うリップルキャリー加算器 --------------------------------------------
//     wire is_sub;
//     wire [31:0] b_xor;
//     wire [4:0]  carry;   // バイト単位のキャリー連鎖 (carry[4] は最終キャリーアウト)
//     wire [3:0]  link_en; // バイト位置ごとのキャリーイネーブル
//     wire [31:0] add_sum;

//     assign is_sub = (C == `SUB)  | (C == `ISUB);

//     // B' = B xor sub, cin = sub
//     assign b_xor   = B ^ {32{is_sub}};
//     assign carry[0] = is_sub;

//     // Carry link enable: 1 allows carry to flow to next byte; 0 cuts and injects sub as new cin
//     // link_en[0]: byte0->byte1, link_en[1]: byte1->byte2, link_en[2]: byte2->byte3, link_en[3]: byte3 final cout
//     assign link_en = (P == 2'b10) ? 4'b1000 : // byte: cut all inter-byte carries
//                      (P == 2'b00) ? 4'b1101 : // halfword: cut between lower and upper half
//                                       4'b1111; // word (11 or 01): no cut

//     genvar bi;
//     generate
//         for (bi = 0; bi < 4; bi = bi + 1) begin : ADDER_BYTE
//             wire cout_raw;
//             assign {cout_raw, add_sum[8*bi +: 8]} = A[8*bi +: 8] + b_xor[8*bi +: 8] + carry[bi];
//             assign carry[bi+1] = link_en[bi] ? cout_raw : is_sub;
//         end
//     endgenerate

//     // Operation results ---------------------------------------------------
//     wire [32:0] add_res;
//     wire [32:0] and_res;
//     wire [32:0] or_res;
//     wire [32:0] xor_res;
//     reg  [32:0] X; // selected result (33-bit to keep carry)

//     assign add_res = {carry[4], add_sum};
//     assign and_res = {1'b0, A & B};
//     assign or_res  = {1'b0, A | B};
//     assign xor_res = {1'b0, A ^ B};

//     always @* begin
//         case (C)
//             `ADD, `SUB, `IADD, `ISUB: X = add_res;
//             `IAND: X = and_res;
//             `IOR : X = or_res;
//             `IXOR: X = xor_res;
//             default: X = add_res; // fallback to add/sub path
//         endcase
//     end

//     // Flags ---------------------------------------------------------------
//     wire overflowFlag; // overflow flag
//     wire zeroFlag; // zero flag
//     wire lessThanUnsignedFlag; // less than unsigned flag
//     wire lessThanFlag; // less than flag

//     // ワード時のみ従来のオーバーフロー判定を使用。パック(8/16bit)時は無効化。
//     // オーバーフローは33bit結果Xを用いて判定（符号ビットと結果の符号で判断）
//     assign overflowFlag = ((P == 2'b11) || (P == 2'b01)) ?
//                             ((~A[31] & B[31] & X[31]) | (A[31] & ~B[31] & ~X[31])) :
//                             1'b0;
//     // Zeroは32bit全体で判定
//     assign zeroFlag = (X[31:0] == 32'b0);
//     // Unsigned less-than は 33bit減算のキャリ（X[32]）を使う
//     assign lessThanUnsignedFlag = X[32];
//     // Signed less-than は overflow と 結果の符号で判定
//     assign lessThanFlag = overflowFlag ^ X[31];

//     // Output MUX ----------------------------------------------------------
//     always @* begin
//         case( C )
//             `lessThan             : Y = {31'b0, lessThanFlag};
//             `lessThanUnsigned     : Y = {31'b0, lessThanUnsignedFlag};
//             `greaterEqual         : Y = {31'b0, ~lessThanFlag};
//             `greaterEqualUnsigned : Y = {31'b0, ~lessThanUnsignedFlag};
//             `equal                : Y = {31'b0, zeroFlag};
//             `notEqual             : Y = {31'b0, ~zeroFlag};
//             default               : Y = X[31:0];
//         endcase
//     end
// endmodule

// 1bitずつ分割するALUモジュール
// module alu ( A, B, C, P, Y );
//     input [31:0] A;
//     input [31:0] B;
//     input [4:0]  C;
//     input [1:0]  P; // PACK SIZE. 11: word, 10: byte, 00: halfword (01 is treated as word)
//     output [31:0] Y;
//     reg [31:0] Y;

//     // Split-carry ripple adder --------------------------------------------
//     wire is_sub;
//     wire [31:0] b_xor;
//     wire [32:0] carry;
//     wire [31:0] link_en; // carry enable per bit position
//     wire [31:0] add_sum;

//     assign is_sub = (C == `SUB)  | (C == `ISUB);

//     // B' = B xor sub, cin = sub
//     assign b_xor   = B ^ {32{is_sub}};
//     assign carry[0] = is_sub;

//     // Carry link enable: 1 allows carry to flow to next bit; 0 cuts and injects sub as new cin
//     assign link_en = (P == 2'b10) ? 32'hFF7F7F7F : // byte: cut at bits 7,15,23
//                      (P == 2'b00) ? 32'hFFFF7FFF : // halfword: cut at bit 15
//                                       32'hFFFFFFFF; // word (11 or 01): no cut

//     genvar i;
//     generate
//         for (i = 0; i < 32; i = i + 1) begin : ADDER
//             wire cout_raw;
//             assign {cout_raw, add_sum[i]} = A[i] + b_xor[i] + carry[i];
//             assign carry[i+1] = link_en[i] ? cout_raw : is_sub;
//         end
//     endgenerate

//     // Operation results ---------------------------------------------------
//     wire [32:0] add_res;
//     wire [32:0] and_res;
//     wire [32:0] or_res;
//     wire [32:0] xor_res;
//     reg  [32:0] X; // selected result (33-bit to keep carry)

//     assign add_res = {carry[32], add_sum};
//     assign and_res = {1'b0, A & B};
//     assign or_res  = {1'b0, A | B};
//     assign xor_res = {1'b0, A ^ B};

//     always @* begin
//         case (C)
//             `ADD, `SUB, `IADD, `ISUB: X = add_res;
//             `IAND: X = and_res;
//             `IOR : X = or_res;
//             `IXOR: X = xor_res;
//             default: X = add_res; // fallback to add/sub path
//         endcase
//     end

//     // Flags ---------------------------------------------------------------
//     wire overflowFlag; // overflow flag
//     wire zeroFlag; // zero flag
//     wire lessThanUnsignedFlag; // less than unsigned flag
//     wire lessThanFlag; // less than flag

//     // ワード時のみ従来のオーバーフロー判定を使用。パック(8/16bit)時は無効化。
//     // オーバーフローは33bit結果Xを用いて判定（符号ビットと結果の符号で判断）
    // assign overflowFlag = ((P == 2'b11) || (P == 2'b01)) ?
    //                         ((~A[31] & B[31] & X[31]) | (A[31] & ~B[31] & ~X[31])) :
    //                         1'b0;
//     // Zeroは32bit全体で判定
//     assign zeroFlag = (X[31:0] == 32'b0);
//     // Unsigned less-than は 33bit減算のキャリ（X[32]）を使う
//     assign lessThanUnsignedFlag = X[32];
//     // Signed less-than は overflow と 結果の符号で判定
//     assign lessThanFlag = overflowFlag ^ X[31];

//     // Output MUX ----------------------------------------------------------
//     always @* begin
//         case( C )
//             `lessThan             : Y = {31'b0, lessThanFlag};
//             `lessThanUnsigned     : Y = {31'b0, lessThanUnsignedFlag};
//             `greaterEqual         : Y = {31'b0, ~lessThanFlag};
//             `greaterEqualUnsigned : Y = {31'b0, ~lessThanUnsignedFlag};
//             `equal                : Y = {31'b0, zeroFlag};
//             `notEqual             : Y = {31'b0, ~zeroFlag};
//             default               : Y = X[31:0];
//         endcase
//     end
// endmodule

// オリジナル
module alu(A, B, C, P, Y);
    input [31:0] A;
    input [31:0] B;
    input [4:0]  C;
    output [31:0] Y;
    reg [31:0] Y;
    reg [32:0] X;  // オーバーフロー検出のための33bitレジスタ

    wire overflowFlag;
    wire zeroFlag;
    wire lessThanUnsignedFlag;
    wire lessThanFlag;

    always @(A or B or C) begin 
        case(C)
            `ADD : X <= { 1'b0, A } + { 1'b0, B };
            `SUB : X <= { 1'b0, A } - { 1'b0, B };
            `IADD : X <= { 1'b0, A } + { 1'b0, B };
            `IAND : X <= { 1'b0, A } & { 1'b0, B };
            `IOR  : X <= { 1'b0, A } | { 1'b0, B };
            `IXOR : X <= { 1'b0, A } ^ { 1'b0, B };
            default: X <= { 1'b0, A } - { 1'b0, B };
        endcase

    end

    assign overflowFlag = (~A[31] & B[31] & X[31]) | (A[31] & ~B[31] & ~X[31]);
    assign zeroFlag = (X[31:0] == 32'b0);
    assign lessThanUnsignedFlag = X[32];
    assign lessThanFlag = overflowFlag ^ X[31];

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