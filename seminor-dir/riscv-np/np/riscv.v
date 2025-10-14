`include "riscv.vh"
`include "inst.vh"
`include "alu.vh"

module riscv
	#(
		parameter IMEM_BASE = 32'h0000_0000,
		parameter IMEM_SIZE = 32768,	// 32kW = 128kB
		parameter IMEM_FILE = "prog.mif",
		parameter DMEM_BASE = 32'h0010_0000,
		parameter DMEM_SIZE = 32768,	// 32kW = 128kB
		parameter DMEM_FILE = "data.mif"
	)
	(
		input CLK,
		input RSTN,
		output reg [31:0] WE_RD_VAL
	);

	wire RST;
	assign RST = ~RSTN

	//命令メモリ(IM)定義 32bit
	reg [31:0] imem[0:IMEM_SIZE-1];

	initial
		begin
			$readmemh( IMEM_FILE, imem );
		end
	
	reg [31:0] PC;
	wire [31:0] PC4;
	wire [31:0] IDARA; //命令データ.
	wire [31:0] IR; //命令レジスタ
	wire [31:0] RF_DATA1;
	wire [31:0] RF_DATA2;

	reg [4:0] ALU_OPERATION; //(IALU) 命令を一意に定める.
	
	assign PC4 = PC + 4;

	always @( posedge CLK or posedge RST)
		begin
			if (RST)
				PC <= 32'h00000000;
			else
				PC <= PC4;
		end	

	assign IDATA = imeme[ PC[31:2] ]

	   // Instruction Aligner for Big/Little endian
`ifdef BIG_ENDIAN
   assign IR = IDATA;
`endif
`ifdef LITTLE_ENDIAN
   assign IR = { IDATA[ 7:0], IDATA[15: 8], IDATA[23:16], IDATA[31:24] };
`endif

// ID
// - IALUに命令の
	always @( IR )
		begin 
			IALU <= `ADD // デフォルトでadd命令

			case(`IR_OP) // 命令タイプの判別
				`OP_FUNC2: // Rタイプ命令のオペコードが定義されている
					case(`IR_F3) // さらに細かく判別する.
					3'b000: // addとsubのみこれ
						begin
						if( `IR_F7 == 7'b0000000) IALU <= `ADD; // [31:25]のfunct1で判別可能
						else if(`IR_F7 == 7'b0000000) IALU <= `SUB;
					end
					endcase
			endcase
		end

   // Regster File
   rf rf( .CLK(CLK), .RNUM1(`IR_RS1), .RDATA1(RF_DATA1), 
                     .RNUM2(`IR_RS2), .RDATA2(RF_DATA2),
                     .WNUM (D_RD),    .WDATA (WB_RD_VAL) );







endmodule