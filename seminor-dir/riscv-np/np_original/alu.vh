//        R-type  I-type  F3  F7
// ADD    0110011 0010011 000 0000000 
// SUB    0110011 0010011 000 0100000 
// SLT    0110011 0010011 010 0000000 
// SLTU   0110011 0010011 011 0000000 
// XOR    0110011 0010011 100 0000000 
// OR     0110011 0010011 110 0000000 
// AND    0110011 0010011 111 0000000 
//
// MUL    0110011         000 0000001
// MULH   0110011         001 0000001
// MULHSU 0110011         010 0100001
// MULHU  0110011         011 0000001
//
// DIV    0110011         000 0000001
// DIVU   0110011         001 0000001
// REM    0110011         010 0100001
// REMU   0110011         011 0000001
//
//        B-type
// BEQ    1100011         000
// BNE    1100011         001
// BLT    1100011         100
// BGE    1100011         101
// BLTU   1100011         110
// BGEU   1100011         111

`define ADD  5'b00101
`define SUB  5'b00110

`define IADD  5'b00000
`define IAND  5'b00001
`define IOR   5'b00010
`define IXOR  5'b00011
`define ISUB  5'b00100
`define lessThan             5'b01000
`define lessThanUnsigned     5'b01001
`define greaterEqual         5'b01010
`define greaterEqualUnsigned 5'b01011
`define equal                5'b01100
`define notEqual             5'b01101

// Shifter
`define ISLL	5'b10001 
`define ISRL	5'b10011 
`define ISRA	5'b10010 

// Multiplyer
`define IMUL	5'b11000
`define IMULH	5'b11001
`define IMULHSU	5'b11010
`define IMULHU	5'b11011

// // Divider
// `define IDIV	5'b11100
// `define IDIVU	5'b11101
// `define IREM	5'b11110
// `define IREMU	5'b11111

// `define PADD.B 5'b11100
// `define PSUB.B 5'b11101
// `define PADD.H 5'b11110
// `define PSUB.H 5'b11111
