// filepath: /Users/motodakoutaroukari/Documents/workspace/github.com/KotaroMotoda/rv32i-pipeline-processor/seminor-dir/riscv-np/np/inst.vh
`define IR_OP   IR[6:0]
`define IR_RS1  IR[19:15]
`define IR_RS2  IR[24:20]
`define IR_RD   IR[11:7]
`define IR_F3   IR[14:12]
`define IR_F7   IR[31:25]

// Operation codes
`define OP_LUI   7'b0110111
`define OP_AUIPC 7'b0010111
`define OP_JAL   7'b1101111
`define OP_JALR  7'b1100111
`define OP_BR    7'b1100011
`define OP_LOAD  7'b0000011
`define OP_STORE 7'b0100011
`define OP_FUNC1 7'b0010011
`define OP_FUNC2 7'b0110011

// Function types
`define FT_U    3'b000
`define FT_J    3'b001
`define FT_B    3'b010
`define FT_I    3'b011
`define FT_S    3'b100
`define FT_R    3'b101

// ALU operations
`define IADD  5'b00000
`define ISUB  5'b00001
`define IAND  5'b00010
`define IOR   5'b00011
`define IXOR  5'b00100
`define ISLL  5'b00101
`define ISRL  5'b00110
`define ISRA  5'b00111
`define ISLT  5'b01000
`define ISLTU 5'b01001

// Control signals
`define MEM_READ  2'b01
`define MEM_WRITE 2'b10
`define MEM_NONE  2'b00

// Other defines can be added as needed for the project.