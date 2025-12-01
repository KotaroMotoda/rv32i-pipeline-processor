module riscv_core
  ( 
    input CLK,
    input RSTN,
    // for IMEM
    input  [31:0] IDATA, 	// Read Instruction for Instruction Memory
    input         IVALID,	// Instruction Valid
    output [31:0] IADDR,	// Address for  Instruction Memory
    // for DMEM
    input  [31:0] DATAI, 	// Read Data for Data Memory
    output [31:0] DADDR,	// Address for  Data Memory
    output [31:0] DATAO,  	// Write Data for Data Memory
    output  [1:0] DWE,		// Weite Enable for Data Memory
    output  [1:0] DRE,		// Read  Enable for Data Memory
    output        DSE		// Sign  Extend for Data Memory
    );

   // for D stage
   wire [31:0] IR;
   wire [31:0] FD_PC;
   wire [31:0] FD_PC4;
// wire [31:0] D_PC_VAL;

   // for EX stage
   wire [ 4:0] DE_RD;
   wire [ 4:0] DE_RS1;
   wire [31:0] DE_RS1_VAL;
   wire        DE_RS1_PC;
   wire [ 4:0] DE_RS2;
   wire [31:0] DE_RS2_VAL;
   wire [31:0] DE_IMM;
   wire [31:0] DE_PC;
   wire [31:0] DE_PC4;
   wire [ 1:0] DE_WB_MUX;
   wire [ 1:0] DE_DMEM_WE; // DMEM write enable,  00: no write, 01: byte, 10: h-word, 11: word
   wire [ 1:0] DE_DMEM_RE; // DMEM read  enable,  00: no read,  01: byte, 10: h-word, 11: word
   wire        DE_DMEM_SE; // SignEx control for load inst,  1: signed, 0: unsigned
   wire [ 4:0] DE_ALU;     // ALU operation
   wire [ 2:0] DE_FT;      // Instruction format type
   wire        DF_NOP;     // instruction fetch cancel for control dependency
   wire        DE_PC_E;
   wire        D_LD_HAZARD;
   wire        E_PC_E;
   wire [31:0] E_PC_VAL;
   // for MEM stage
   wire [ 4:0] EM_RD;
   wire [31:0] EM_RD_VAL;
   wire [31:0] EM_PC4;
   wire [ 1:0] EM_WB_MUX;  // WB_MUX control
// wire        DVALID;
   wire [31:0] MW_RD_VAL;
   wire [31:0] MW_MEM_VAL;
   wire [31:0] MW_PC4;
   // for WB stage
   wire [ 4:0] WB_RD;
   reg  [31:0] WB_RD_VAL;
   wire [ 1:0] WB_MUX;

   // IF stage
   fstage i_f
     (
      .CLK(CLK),	// clock
      .RSTN(RSTN),	// reset
      //	       .PC_D(),     // PC write enable from D stage (beq, bne, jal)
      .PC_E(E_PC_E),     // PC write enable from E stage (jalr, blt, bltu, bge, bgeu)
      .DF_NOP(DF_NOP),    // instruction fetch cancel for control dependency
      .D_LD_HAZARD(D_LD_HAZARD),
      //	       .D_PC_VAL(D_PC_VAL), // target address from D stage for beq & bne
      .E_PC_VAL(E_PC_VAL), // target address from E stage for jalr, branch
      .IR(IR),    // IR   to D stage
      .FD_PC(FD_PC),    // PC   to D stage
      .FD_PC4(FD_PC4),    // PC+4 to D stage
      .IADDR(IADDR),
      .IDATA(IDATA),
      .IVALID(IVALID)
      );

   // D stage
   dstage 
     i_d
       (
	.CLK(CLK), // clock
	.RSTN(RSTN), // reset
	.IR(IR), // IP   from F stage
	.FD_PC(FD_PC), // PC   from F stage
	.FD_PC4(FD_PC4), // PC+4 from F stage
	.WB_RD(WB_RD), // destination reg from M stage
	.WB_RD_VAL(WB_RD_VAL), // destination val from M stage
	.E_PC_E(E_PC_E),      // enable for target address (flush D stage)
	.DE_RD(DE_RD),      // destination reg to   E stage
	.DE_RS1(DE_RS1),     // source 1    reg to   E stage
	.DE_RS1_VAL(DE_RS1_VAL), // source 1    val to   E stage
	.DE_RS2(DE_RS2),     // source 2    reg to   E stage
	.DE_RS2_VAL(DE_RS2_VAL), // source 2    val to   E stage
	.DE_IMM(DE_IMM),     // IMM         val to   E stage
	.DE_PC(DE_PC),      // PC          val to   E stage
	.DE_PC4(DE_PC4),	    // PC+4        val to   E stage
	.DE_WB_MUX(DE_WB_MUX),
	.DE_DMEM_WE(DE_DMEM_WE), // DMEM write enable,  00: no write, 01: byte, 10: h-word, 11: word
	.DE_DMEM_RE(DE_DMEM_RE), // DMEM read  enable,  00: no read,  01: byte, 10: h-word, 11: word
	.DE_DMEM_SE(DE_DMEM_SE),  // SignEx control for load inst,  1: signed, 0: unsigned
	.DE_ALU(DE_ALU), // ALU operation
	.DE_FT(DE_FT),  // Instruction format type
	.DE_RS1_PC(DE_RS1_PC), // auipc and branch
	.DE_PC_E(DE_PC_E),  // auipc and branch
	.DF_NOP(DF_NOP),     // instruction fetch cancel for control dependency
	.D_LD_HAZARD(D_LD_HAZARD)
	//	       .D_PC_VAL(D_PC_VAL)    // target address for beq, bne, jal inst.
	);
   
   
   // EX stage
   estage
     i_e
       (
	.CLK(CLK),	       // clock
	.RSTN(RSTN),	       // reset
	.DE_RD(DE_RD),	       // destination reg to   E stage
	.DE_RS1(DE_RS1),	       // source 1    reg to   E stage
	.DE_RS1_VAL(DE_RS1_VAL), // source 1    val to   E stage
	.DE_RS2(DE_RS2),	       // source 2    reg to   E stage
	.DE_RS2_VAL(DE_RS2_VAL), // source 2    val to   E stage
	.DE_IMM(DE_IMM),	       // IMM         val to   E stage
	.DE_PC(DE_PC),	       // PC          val to   E stage
	.DE_PC4(DE_PC4),	       // PC+4        val to   E stage
	.DE_WB_MUX(DE_WB_MUX),
	.DE_DMEM_WE(DE_DMEM_WE), // DMEM write enable,  00: no write, 01: byte, 10: h-word, 11: word
	.DE_DMEM_RE(DE_DMEM_RE), // DMEM read  enable,  00: no read,  01: byte, 10: h-word, 11: word
	.DE_DMEM_SE(DE_DMEM_SE),  // SignEx control for load inst,  1: signed, 0: unsigned
	.DE_ALU(DE_ALU), // ALU operation
	.DE_FT(DE_FT),  // Instruction format type
	.DE_RS1_PC(DE_RS1_PC),  // auipc and branch
	.DE_PC_E(DE_PC_E),    // branch target address to fstage for branch inst
	
	.WB_RD(WB_RD),      // destination reg from M/W for forwarding 
	.WB_RD_VAL(WB_RD_VAL),  // destination val from M/W for forwarding 
	
	.EM_RD(EM_RD),
	.EM_RD_VAL(EM_RD_VAL),   // EM_RD_VAL, ALU result or data Memory address
	.EM_RS2_VAL(DATAO), // EM_RS2_VAL for store data
	.EM_PC4(EM_PC4),         // PC+4 for jal and jalr destination
	.EM_WB_MUX(EM_WB_MUX),   // WB_MUX control
       	.EM_DMEM_WE(DWE), // DMEM write  enable,  00: no read,  01: byte, 10: h-word, 11: word
	.EM_DMEM_RE(DRE), // DMEM read   enable,  00: no read,  01: byte, 10: h-word, 11: word
	.EM_DMEM_SE(DSE), // SignEx control for load inst,  1: signed, 0: unsigned
	
	.E_PC_VAL(E_PC_VAL), // target address for jalr, blt, bltu, bge, bgeu
	.E_PC_E(E_PC_E)     // enable for target address
	);


   assign DADDR = EM_RD_VAL;
   
   // MEM stage
   mstage 
   i_m (
	.CLK(CLK),	   // clock
	.RSTN(RSTN),	   // reset
	.EM_RD(EM_RD),	   // destination reg from E/M for forwarding 
	.EM_RD_VAL(EM_RD_VAL),
	.EM_PC4(EM_PC4),
	.EM_WB_MUX(EM_WB_MUX),
	.MW_RD(WB_RD),	      // WB_RD for destination register number
	.MW_RD_VAL(MW_RD_VAL),  // RD_VAL for R & I type inst
	.MW_PC4(MW_PC4),	// PC+4 for jal and jalr destination
	.MW_WB_MUX(WB_MUX)   // control for WB_MUX (00: no WB, 01: load inst, 10: jal & jalr, 11: R&I type)
	);


   // WB stage
   always @( WB_MUX or DATAI or MW_PC4 or MW_RD_VAL )
     begin
	case( WB_MUX )
	2'b01:   WB_RD_VAL <= DATAI;
	2'b10:   WB_RD_VAL <= MW_PC4;
	default: WB_RD_VAL <= MW_RD_VAL;
	endcase // case ( WB_MUX )
     end

endmodule // riscv
