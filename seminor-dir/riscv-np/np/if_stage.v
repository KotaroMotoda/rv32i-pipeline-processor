module if_stage
    #(
        parameter IMEM_BASE = 32'h0000_0000,
        parameter IMEM_SIZE = 32768, // 32kW = 128kB
        parameter IMEM_FILE = "prog.mif"
    )
    (
        input CLK,
        input RSTN,
        output reg [31:0] PC_IF,
        output reg [31:0] IDATA_IF
    );

    wire RST;
    assign RST = ~RSTN;

    // Instruction memory
    reg [31:0] imem[0:IMEM_SIZE-1];

    initial
    begin
        $readmemh(IMEM_FILE, imem);
    end

    // PC calculation
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
            PC_IF <= IMEM_BASE;
        else
            PC_IF <= PC_IF + 4; // Increment PC by 4 for next instruction
    end

    // Fetch instruction
    always @(posedge CLK)
    begin
        IDATA_IF <= imem[PC_IF[31:2]]; // Fetch instruction from memory
    end

endmodule