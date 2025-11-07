`include "riscv.vh"

`timescale 1ns / 1ns

module riscv_tb ();

   reg CLK, RSTN;

`ifdef VCD
   initial
     begin
	// for iverilog + gtkwave and the others
	$dumpfile("riscv.vcd");
	$dumpvars(0, riscv );
     end
`endif
   
   initial
     begin
	CLK = 0;
	while( 1 )
	  CLK = #5 ~CLK;
     end

   //
   // Data Memory Dump for Debug
   //
   task dump;
      input [31:0] addr;

      integer 	   i;
      reg [31:0] data;
      
      for( i = addr ; i<1024 ; i=i+1 )
	begin
	   data = riscv.mem_stage_inst.dmem_inst.mem[i];
	   $display( "%08x %02x%02x%02x%02x", addr+i*4,
		     data[7:0], data[15:8], data[23:16], data[31:24] );
	end
   endtask


   initial
     begin
	RSTN = 1;
	RSTN = #10 0;
	RSTN = #10 1;
	#4000000000;
	dump(0);
	$finish();
     end
   
   always @( posedge CLK )
     if( riscv.PC_IF== 32'h00000064 ) // Last instruction address (ebreak) on "startup.s"
       begin
	  $display("Time", $time );
	  dump(0);
	  $finish;	     
       end
   
   riscv #( .IMEM_FILE("prog.mif"),
	    .DMEM_FILE("data.mif"),
	    .IMEM_SIZE(32768),
	    .DMEM_SIZE(32768)
	    )
   riscv ( .CLK(CLK), .RSTN(RSTN) );

   //
   // Debug code
   //
`ifdef ST_DEBUG
   always @( negedge CLK )
     if(  ( riscv.DMWE ) && ( riscv.MADDR[31:20] == 12'h001 ) )
	 $display( "ST  :%08h %08h %01h ", {riscv.MADDR,2'b00}, riscv.RF_DATA2, riscv.DMWE );
`endif
`ifdef LD_DEBUG
   always @( negedge CLK )
     if(  ( riscv.DMRE  ) && ( riscv.MADDR[31:20] == 12'h001 ) )
       $display( "LD  :%08h %08h %01h ", {riscv.MADDR,2'b00}, riscv.daligner.DATAO, riscv.DMRE );
`endif

endmodule