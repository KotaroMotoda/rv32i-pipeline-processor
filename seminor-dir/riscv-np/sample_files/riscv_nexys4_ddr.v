`include "riscv.vh"

module riscv
  #(
    parameter IMEM_BASE = 32'h0000_0000,
    parameter IMEM_SIZE = 32768,	// 32kW = 128kB
    parameter IMEM_FILE = "prog.mif",
    parameter DMEM_BASE = 32'h0010_0000,
    parameter DMEM_SIZE = 32768,	// 32kW = 128kB
    parameter DMEM_FILE = "data.mif",
    parameter VRAM_BASE = 32'h7ff0_0000,
    parameter VRAM_SIZE = 4096
    )
   ( 
    input 	 SYSCLK,
    input 	 SYSRSTN,
    output [3:0] VGA_R,
    output [3:0] VGA_G,
    output [3:0] VGA_B,
    output 	 VGA_HS,
    output 	 VGA_VS
    );

   wire 	 CLK, CGA_CLK, RSTN, LOCKED;

   wire [31:0] IADDR;
   wire [31:0] IDATA;
   wire        IVALID;
    
   wire [31:0] DADDR;
   wire [31:0] DATAO;
   wire [31:0] DATAI;
   wire [1:0]  DWE;
   wire [1:0]  DRE;
   wire        DSE;

   wire [31:2] MADDR;
   wire [31:0] MDATAI, MDATAI_DMEM, MDATAI_VRAM;
   wire [31:0] MDATAO;
   wire [ 3:0] MWSTB;

   wire        CEM, CEV;
   
   
   //
   // Clock module
   //
   clk_wiz_0 clk_module (
       .clk_in1( SYSCLK ),
       .clk_out1( CLK ),
       .reset( ~SYSRSTN ),
       .locked( LOCKED )
   );

   assign CGA_CLK = CLK;
   assign RSTN    = SYSRSTN & LOCKED;
   
   riscv_core riscv_core_0
     (
      .CLK(CLK),
      .RSTN(RSTN),
    
      .IDATA(IDATA),
      .IVALID(IVALID),
      .IADDR(IADDR),
    
      .DATAI(DATAI), 
      .DADDR(DADDR),
      .DATAO(DATAO), 
      .DWE(DWE),
      .DRE(DRE),
      .DSE(DSE)
      );


   imem 
     #(
       .IMEM_SIZE(IMEM_SIZE),
       .PROG(IMEM_FILE)
       )
   i_mem 
     (
      .ADDR(IADDR),
      .DATA(IDATA),
      .VALID(IVALID)
      );

`ifdef ST_DEBUG
   always @( negedge CLK )
	if(  ( DWE == 1 ) && ( DADDR[31:20] == 12'h001 ) )
	  if( DADDR < 32'h00100a00 )
//	    $display( "ST  :%d %08h %08h %01h ", $time, DADDR, DATAO, DWE );
	    $display( "ST  :%08h %08h %01h ", DADDR, DATAO, DWE );
`endif
`ifdef LD_DEBUG
   always @( negedge CLK )
     if(  ( DRE == 1 ) && ( DADDR[31:20] == 12'h001 ) )
//       $display( "LD  :%d %08h %08h %08h %01h ", $time, DADDR , MDATAI, daligner.iDATAO, DRE );
       $display( "LD  :%08h %08h %01h ", DADDR, daligner.iDATAO, DRE );
`endif
`ifdef DMEM_DEBUG
   always @( negedge CLK )
     begin
	if(  ( |DWE ) && ( DADDR[31:20] == 12'h001 ) )
	  if( DADDR >= 32'h00100a00 )
	    $display( "STKS:%d %08h %08h %01h ", $time, DADDR, DATAO, DWE );
	  else
	    $display( "ST  :%d %08h %08h %01h ", $time, DADDR, DATAO, DWE );
	if(  ( |DRE ) && ( DADDR[31:20] == 12'h001 ) )
	  if( DADDR >= 32'h00100a00 )
	    $display( "STKL:%d %08h %08h %01h ", $time, DADDR, MDATAI, DRE );
	  else
	    $display( "LD  :%d %08h %08h %01h ", $time, DADDR, MDATAI, DRE );
	    
     end
`endif
`ifdef VRAM_ST_DEBUG
   always @( negedge CLK )
     if(  ( | DWE ) && ( DADDR[31:20] == 12'h7ff ) )
//       $display( "VMST:%d %08h %08h %01h ", $time, DADDR , DATAO, DWE );
       $display( "VMST:%08h %08h %01h ", DADDR , DATAO, DWE );
`endif
`ifdef VRAM_LD_DEBUG
   always @( negedge CLK )
     if(  ( | DRE) && ( DADDR[31:20] == 12'h7ff ) )
//       $display( "VMLD:%d %08h %08h %08h %01h ", $time, DADDR , MDATAI, daligner.iDATAO, DRE );
       $display( "VMLD:%08h %08h %08h %01h ", DADDR , MDATAI, daligner.iDATAO, DRE );
`endif


   
   daligner daligner
     (
      .CLK(CLK),
      .ADDRI(DADDR),
      .DATAI(DATAO),
      .DATAO(DATAI),
      .WE(DWE), // 00: no write, 01: byte, 10: h-word, 11: word
      .RE(DRE), // 00: no read,  01: byte, 10: h-word, 11: word
      .SE(DSE), // Sign Extend Control
      .MADDR(MADDR),
      .MDATAO(MDATAO),
      .MDATAI(MDATAI),
      .MWSTB(MWSTB)  // Write strobe 0000, 0001, 0010, 0100, 1000, 0011, 1100, 1111
      );

   assign CEM = ( ( |DWE || |DRE ) && (MADDR[31:20] == DMEM_BASE[31:20]) );
   assign CEV = ( ( |DWE || |DRE ) && (MADDR[31:20] == VRAM_BASE[31:20]) );

   assign MDATAI = ( CEM ) ? MDATAI_DMEM : MDATAI_VRAM;
   
   dmem
     #(
       .DMEM_SIZE(DMEM_SIZE),
       .INIT_FILE(DMEM_FILE)
       )
   dmem 
     (
      .CLK(CLK),
      .ADDR(MADDR), 
      .DATAI(MDATAO),
      .DATAO(MDATAI_DMEM), 
      .CE(CEM),
      .WSTB(MWSTB)
      );


   vram d_vram
     (
      .CLK(CLK),
      .RSTN(RSTN),
      .CGA_CLK(CGA_CLK), // 75NHz
      .ADDR(MADDR),
      .DATAI(MDATAO),
      .DATAO(MDATAI_VRAM),
      .CE(CEV),
      .WSTB(MWSTB),
      .R(VGA_R),
      .G(VGA_G),
      .B(VGA_B),
      .HS(VGA_HS),
      .VS(VGA_VS)
      );
   
   
endmodule // riscv_nexys4_ddr
