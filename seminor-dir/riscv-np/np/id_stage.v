module id_stage
    (
        input CLK,
        input RSTN,
        input [31:0] IR,
        input [31:0] PC_FD,
        output reg [4:0] RD_ID,
        output reg [31:0] RF_DATA1,
        output reg [31:0] RF_DATA2,
        output reg [31:0] IMM_VAL_EXT_ID,
        output reg [1:0] MemtoReg_ID,
        output reg RegWrite_ID,
        output reg ALUSrc_ID,
        output reg [1:0] ALUOp_ID,
        output reg [2:0] FT_ID
    );

    // Instruction decoding logic
    always @(IR) begin
        FT_ID <= 3'b000; // default: undefined instruction
        RegWrite_ID <= 1'b0; // default: no register write
        ALUSrc_ID <= 1'b0; // default: use RS2 (R/BR type)
        
        // Decode instruction and set control signals
        case(IR[6:0]) // opcode
            7'b0110011: begin // R-type
                FT_ID <= 3'b001; // R-type format
                RegWrite_ID <= 1'b1; // enable register write
                ALUSrc_ID <= 1'b0; // use RS2
            end
            7'b0000011: begin // I-type Load
                FT_ID <= 3'b010; // I-type format
                RegWrite_ID <= 1'b1; // enable register write
                ALUSrc_ID <= 1'b1; // use immediate
            end
            // Add more cases for other instruction types
        endcase
        
        RD_ID <= IR[11:7]; // destination register
        // Immediate extraction (sign-extend)
        IMM_VAL_EXT_ID <= {{20{IR[31]}}, IR[31:20]}; // default I-type immediate
    end

    // Register file access logic (to be implemented)
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            RF_DATA1 <= 32'b0;
            RF_DATA2 <= 32'b0;
        end else begin
            // Logic to read from register file
        end
    end

endmodule