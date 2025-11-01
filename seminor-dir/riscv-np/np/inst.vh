//
// Opecode field
//
`define IR_OP  	IR[ 6: 0]
`define IR_RD	IR[11: 7]
`define IR_F3	IR[14:12]
`define IR_RS1	IR[19:15]
`define IR_RS2	IR[24:20]
`define IR_F7	IR[31:25]


// opecode
`define OP_LUI		7'b0110111 
`define OP_AUIPC	7'b0010111 
`define OP_JAL		7'b1101111 
`define OP_JALR		7'b1100111 
`define OP_BR		7'b1100011 
`define OP_LOAD		7'b0000011 
`define OP_STORE	7'b0100011 
`define OP_FUNC1	7'b0010011 
`define OP_FUNC2	7'b0110011 
`define OP_FENCEX	7'b0001111 
`define OP_FUNC3	7'b1110011 

// Instruction Format Type ( 00: illegal instruction )
`define FT_R	3'b001
`define FT_I	3'b010
`define FT_S	3'b011
`define FT_U	3'b100
`define FT_J	3'b101
`define FT_B	3'b110


