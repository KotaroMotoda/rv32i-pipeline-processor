module forwarding_unit (
    input  [4:0] RS1_DE,
    input  [4:0] RS2_DE,
    input  [4:0] RD_EM,
    input  [4:0] RD_MW,
    input        RegWrite_EM,
    input        RegWrite_MW,
    output reg [1:0] ForwardA,
    output reg [1:0] ForwardB
);
    // ForwardA: 優先度 EX/MEM > MEM/WB
    always @(*) begin
        if (RegWrite_EM && (RD_EM != 5'd0) && (RD_EM == RS1_DE))
            ForwardA = 2'b10;
        else if (RegWrite_MW && (RD_MW != 5'd0) && (RD_MW == RS1_DE))
            ForwardA = 2'b01;
        else
            ForwardA = 2'b00;
    end

    // ForwardB: 優先度 EX/MEM > MEM/WB
    always @(*) begin
        if (RegWrite_EM && (RD_EM != 5'd0) && (RD_EM == RS2_DE))
            ForwardB = 2'b10;
        else if (RegWrite_MW && (RD_MW != 5'd0) && (RD_MW == RS2_DE))
            ForwardB = 2'b01;
        else
            ForwardB = 2'b00;
    end
endmodule