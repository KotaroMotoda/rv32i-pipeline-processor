module rf (
    input CLK,
    input [4:0] RNUM1,
    output [31:0] RDATA1,
    input [4:0] RNUM2,
    output [31:0] RDATA2,
    input [4:0] WNUM,
    input [31:0] WDATA,
    input RegWrite
);
    reg [31:0] registers [0:31];

    always @(posedge CLK) begin
        if (RegWrite) begin
            registers[WNAM] <= WDATA;
        end
    end

    assign RDATA1 = registers[RNUM1];
    assign RDATA2 = registers[RNUM2];
endmodule