`include "alu.vh"

//                                                  R-type   I-type   F3  F7
// C: 10001 -- sll, slli  -- shift left logical     0110011, 0010011, 001 0000000
// C: 10011 -- srl, srli  -- shift right logical    0110011, 0010011, 101 0000000
// C: 10010 -- sra, srai  -- shift right arithmetic 0110011, 0010011, 101 0100000
// C: 10000 -- don't care ( same as sra, but don't use result )

module shift ( C, A, B, Y );
   input  [ 4:0] C;
   input  [31:0] A;
   input  [ 4:0] B;
   output [31:0] Y;

   reg signed [31:0] tmp;  // ← 符号付きにする

   always @(*) begin
       tmp = A;
       if (B[0]) tmp = (C == `ISLL) ? (tmp <<< 1)  :
                       (C == `ISRL) ? (tmp >> 1)   :
                                      (tmp >>> 1);
       if (B[1]) tmp = (C == `ISLL) ? (tmp <<< 2)  :
                       (C == `ISRL) ? (tmp >> 2)   :
                                      (tmp >>> 2);
       if (B[2]) tmp = (C == `ISLL) ? (tmp <<< 4)  :
                       (C == `ISRL) ? (tmp >> 4)   :
                                      (tmp >>> 4);
       if (B[3]) tmp = (C == `ISLL) ? (tmp <<< 8)  :
                       (C == `ISRL) ? (tmp >> 8)   :
                                      (tmp >>> 8);
       if (B[4]) tmp = (C == `ISLL) ? (tmp <<< 16) :
                       (C == `ISRL) ? (tmp >> 16)  :
                                      (tmp >>> 16);
   end

   assign Y = tmp;
endmodule
