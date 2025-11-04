module rf( CLK, RNUM1, RNUM2, RDATA1, RDATA2, WNUM, WDATA );
   input         CLK;
   input   [4:0] RNUM1, RNUM2, WNUM;
   output reg [31:0] RDATA1, RDATA2;
   input  [31:0] WDATA;

   reg    [31:0] REGISTER_FILE[1:31];

   // write: 同期
   always @( posedge CLK ) begin
      if (WNUM != 5'b00000)
         REGISTER_FILE[WNUM] <= WDATA;
   end

   // read: 非同期（組み合わせ）
   always @* begin
      RDATA1 = (RNUM1 != 5'd0) ? REGISTER_FILE[RNUM1] : 32'h0000_0000;
      RDATA2 = (RNUM2 != 5'd0) ? REGISTER_FILE[RNUM2] : 32'h0000_0000;
   end
endmodule
