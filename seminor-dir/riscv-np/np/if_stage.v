module if_stage
    #(
        parameter IMEM_BASE = 32'h0000_0000,
        parameter IMEM_SIZE = 32768,	
        parameter IMEM_FILE = "prog.mif"
    )
    (
        input  CLK,
        input  RST,
        input  isBranch_E,
        input  [31:0] PC_IMM_E,
        input  stall_IF,          
        output reg [31:0] PC_IF,
        output [31:0] PC4_IF,    
        output [31:0] IDATA_IF
    );

    // IMEM
    reg [31:0] imem[0:IMEM_SIZE-1];
    initial begin
        $readmemh(IMEM_FILE, imem);
    end

    assign PC4_IF = PC_IF + 4;

    always @(posedge CLK or posedge RST) begin
        if (RST)
            PC_IF <= 32'h0000_0000;
        else if (isBranch_E)
            PC_IF <= PC_IMM_E;
        else if (stall_IF)
            PC_IF <= PC_IF;
        else
            PC_IF <= PC4_IF;
    end

    assign IDATA_IF = imem[PC_IF[31:2]];

endmodule