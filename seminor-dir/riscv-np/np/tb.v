`include "riscv.vh"

`timescale 1ns / 1ns

module riscv_tb ();

   reg CLK, RSTN;
  integer dump_i;  // initial ブロックで使うループ変数

`ifdef VCD
   initial begin
      $dumpfile("riscv.vcd");
      $dumpvars(0, riscv );
   end
`endif

   initial begin
      CLK = 0;
      while(1) CLK = #5 ~CLK;
   end

   // Data Memory Dump
   task dump;
      input [31:0] addr;
      integer i;
      reg [31:0] data;
      for (i = addr; i < 1024; i = i + 1) begin
         data = riscv.dmem_inst.mem[i];
         $display("%08x %02x%02x%02x%02x", addr + i*4,
                  data[7:0], data[15:8], data[23:16], data[31:24]);
      end
   endtask

   initial begin
      RSTN = 1;
      RSTN = #10 0;
      RSTN = #10 1;
      #4000000000;
      dump(0);
      $finish();
   end

   always @(posedge CLK)
     if (riscv.core.PC_IF == 32'h00000064) begin
        $display("Time", $time);
        dump(0);
        $finish;
     end

   // IMEM_* のパラメータ指定は削除（IMはコア内）
   riscv #(
      .DMEM_FILE("data.mif"),
      .DMEM_SIZE(32768)
   ) riscv (
      .CLK(CLK),
      .RSTN(RSTN)
   );

`ifdef ST_DEBUG
   always @(negedge CLK)
     if ((|riscv.MemWrite_EM) && (riscv.MADDR[31:20] == 12'h001))
       $display("ST  :%08h %08h %04b ", {riscv.MADDR,2'b00}, riscv.MDATAO, riscv.MWSTB);
`endif
`ifdef LD_DEBUG
   always @(negedge CLK)
     if ((|riscv.MemRead_EM) && (riscv.MADDR[31:20] == 12'h001))
       $display("LD  :%08h %08h %02b ", {riscv.MADDR,2'b00}, riscv.MEM_DATA_M, riscv.MemRead_EM);
`endif

   initial begin
      for (dump_i=0; dump_i<32768; dump_i=dump_i+1) $dumpvars(0, riscv.dmem_inst.mem[dump_i]);
   end

   initial begin
      $dumpvars(0, riscv.core.PC_IF);
   end

endmodule