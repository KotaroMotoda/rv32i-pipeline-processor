`timescale 1ns / 1ns
`include "alu.vh"
module alu_test ();
reg [31:0] A, B;
reg [ 4:0] C;
wire [31:0] Y;
`include "alu_test.vct"
initial
begin
$monitorh( C, " ", A, " ", B, " ", Y );
end
alu dut ( .C(C), .A(A), .B(B), .Y(Y) );
endmodule