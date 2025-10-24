`include "riscv.vh"
`include "inst.vh"
`include "alu.vh"
`define LITTLE_ENDIAN


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
    assign RST = ~RSTN;

    // IM 
    reg [31:0] imem[0:IMEM_SIZE-1];

    initial
    begin
        $readmemh( IMEM_FILE, imem );
    end

    // IF reg
    reg [31:0] PC_IF;
    wire [31:0] PC4_IF;
    wire [31:0] IDATA_IF;

    // IF/ID pipeline reg
    reg [31:0] PC_FD;
    reg [31:0] IDATA_FD;
    reg [31:0] PC4_FD;

    // ID reg
    wire [31:0] IR;
    reg [4:0] IALU_ID;
    wire [31:0] RF_DATA1;
    wire [31:0] RF_DATA2;
    reg [4:0] RD_ID;
    reg [2:0] FT_ID;

    // ID/EX pipeline reg
    reg [31:0] PC_DE;
    wire [31:0] PC4_DE;
    reg [31:0] RF_DATA1_DE;
    reg [31:0] RF_DATA2_DE;
    reg [4:0] IALU_DE;
    reg [4:0] RD_DE;

    // EX reg
    wire [31:0] RD_VAL_E;
    reg [31:0] DATA1_MUX_E;
    reg [31:0] DATA2_MUX_E;

    // EX/MEM pipeline reg
    wire [31:0] PC4_EM;
    reg [31:0] RD_VAL_EM;
    reg [4:0] RD_EM;

    // MEM/WB pipeline reg
    wire [31:0] PC4_MW; 
    reg [31:0] RD_VAL_MW;
    reg [4:0] RD_MW;

    // WB reg
    reg [31:0] MUX_W;

    // IF stage
    assign PC4_IF = PC_IF + 4;
    
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
            PC_IF <= 32'h00000000;
        else
            PC_IF <= PC4_IF;
    end	

    assign IDATA_IF = imem[PC_IF[31:2]];

    // IF/ID pipeline reg update
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            PC_FD <= 32'h00000000;
            PC4_FD <= 32'h00000004;
            IDATA_FD <= 32'h00000000;
        end
        else
        begin
            PC_FD <= PC_IF;
            PC4_FD <= PC4_IF;
            IDATA_FD <= IDATA_IF;
        end
    end

    // define IR
    `ifdef BIG_ENDIAN
    assign IR = IDATA_FD;
    `endif
    `ifdef LITTLE_ENDIAN
    assign IR = {IDATA_FD[7:0], IDATA_FD[15:8], IDATA_FD[23:16], IDATA_FD[31:24]};
    `endif

    // ID stage
    always @(IR)
    begin
        case 
            (`IR_OP)
            `OP_FUNC2 : // R type
	    begin
	       case( `IR_F3 )
		 3'b000 : 
		   begin
		      if( `IR_F7 == 7'b0000000 ) IALU_ID <= `IADD; else // add
		      if( `IR_F7 == 7'b0100000 ) IALU_ID <= `ISUB;      // sub
                   end 
		 3'b001 : 
		   begin
		      if( `IR_F7 == 7'b0000000 ) IALU_ID <= `ISLL;      // sll
                   end 
		 3'b010 : 
		   begin
		      if( `IR_F7 == 7'b0000000 ) IALU_ID <= `lessThan;       // slt
                   end 
		 3'b011 : 
		   begin
		      if( `IR_F7 == 7'b0000000 ) IALU_ID <= `lessThanUnsigned;      // sltu
                   end
		 3'b100 : 
		   begin
		      if( `IR_F7 == 7'b0000000 ) IALU_ID <= `IXOR;      // xori
                   end
		 3'b101 : 
		   begin
		      if( `IR_F7 == 7'b0000000 ) IALU_ID <= `ISRL; else // srl
		      if( `IR_F7 == 7'b0100000 ) IALU_ID <= `ISRA;      // sra
                   end 
		 3'b110 : 
		   begin 
		      if( `IR_F7 == 7'b0000000 ) IALU_ID <= `IOR;       // ori
                   end 
		 3'b111 : 
		   begin
		      if( `IR_F7 == 7'b0000000 ) IALU_ID <= `IAND;      // andi
                   end
	       endcase // case ( `IR_F3 )
	    end
        endcase
        RD_ID <= `IR_RD;
    end

    // rf
    rf rf_inst(
        .CLK(CLK),
        .RNUM1(`IR_RS1), .RDATA1(RF_DATA1),
        .RNUM2(`IR_RS2), .RDATA2(RF_DATA2),
        .WNUM(RD_MW),    .WDATA(RD_VAL_MW)
    );

    // ID/EX pipeline reg update
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            PC_DE <= 32'h00000000;
            RF_DATA1_DE <= 32'h00000000;
            RF_DATA2_DE <= 32'h00000000;
            IALU_DE <= 5'b00000;
            RD_DE <= 5'b00000;
        end
        else
        begin
            PC_DE <= PC_FD;
            RF_DATA1_DE <= RF_DATA1;
            RF_DATA2_DE <= RF_DATA2;
            IALU_DE <= IALU_ID;
            RD_DE <= RD_ID;
        end
    end

    // EX stage
    alu alu_inst(
        .A(RF_DATA1_DE), 
        .B(RF_DATA2_DE), 
        .C(IALU_DE), 
        .Y(RD_VAL_E)
    );

    // EX/MEM pipeline reg update
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            PC_EM <= 32'h00000000;
            RD_VAL_EM <= 32'h00000000;
            RD_EM <= 5'b00000;
        end
        else
        begin
            PC_EM <= PC_DE;
            RD_VAL_EM <= RD_VAL_E;
            RD_EM <= RD_DE;
        end
    end

    // MEM/WB pipeline reg update
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            PC_MW <= 32'h00000000;
            RD_VAL_MW <= 32'h00000000;
            RD_MW <= 5'b00000;
        end
        else
        begin
            PC_MW <= PC_EM;
            RD_VAL_MW <= RD_VAL_EM;
            RD_MW <= RD_EM;
        end
    end

    // define output
    always @(posedge CLK)
    begin
        WE_RD_VAL <= RD_VAL_MW;
    end

endmodule