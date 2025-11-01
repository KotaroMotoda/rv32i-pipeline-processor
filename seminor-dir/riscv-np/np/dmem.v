module dmem
    #(
        parameter DMEM_BASE = 32'h0010_0000,
        parameter DMEM_SIZE = 32768, // 32kW = 128kB
        parameter DMEM_FILE = "data.mif"
    )
    (
        input CLK,
        input [31:0] A, // Address
        input [31:0] WD, // Write Data
        input WE, // Write Enable
        output reg [31:0] RD // Read Data
    );

    reg [31:0] dmem[0:DMEM_SIZE-1];

    initial
    begin
        $readmemh(DMEM_FILE, dmem);
    end

    always @(posedge CLK)
    begin
        if (WE)
            dmem[A[31:2]] <= WD; // Write data to memory
    end

    always @(*)
    begin
        RD = dmem[A[31:2]]; // Read data from memory
    end

endmodule