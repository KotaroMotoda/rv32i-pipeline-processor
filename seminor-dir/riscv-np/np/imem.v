module imem
    #(
        parameter IMEM_BASE = 32'h0000_0000,
        parameter IMEM_SIZE = 32768, // 32kW = 128kB
        parameter IMEM_FILE = "prog.mif"
    )
    (
        input [31:0] addr,
        output reg [31:0] data
    );

    reg [31:0] imem[0:IMEM_SIZE-1];

    initial
    begin
        $readmemh(IMEM_FILE, imem);
    end

    always @(*)
    begin
        data = imem[addr[31:2]];
    end
endmodule