module ex_stage (
    input CLK,
    input RST,
    input [31:0] DATA1_MUX_E,
    input [31:0] DATA2_MUX_E,
    input [4:0] IALU_DE,
    output reg [31:0] RD_VAL_E
);

    // ALU instance
    alu alu_inst (
        .A(DATA1_MUX_E),
        .B(DATA2_MUX_E),
        .C(IALU_DE),
        .Y(RD_VAL_E)
    );

endmodule