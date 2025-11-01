module hazard_unit (
    input wire CLK,
    input wire RSTN,
    input wire [4:0] ID_EX_RD,
    input wire ID_EX_RegWrite,
    input wire [4:0] IF_ID_RS1,
    input wire [4:0] IF_ID_RS2,
    output reg stall,
    output reg flush
);

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            stall <= 1'b0;
            flush <= 1'b0;
        end else begin
            // Default values
            stall <= 1'b0;
            flush <= 1'b0;

            // Data hazard detection
            if (ID_EX_RegWrite && (ID_EX_RD != 5'b00000) && 
                (ID_EX_RD == IF_ID_RS1 || ID_EX_RD == IF_ID_RS2)) begin
                stall <= 1'b1; // Stall the pipeline
            end

            // Control hazard detection (example)
            // This is a placeholder for control hazard logic
            // Implement specific logic based on branch instructions
            // if (branch_condition) begin
            //     flush <= 1'b1; // Flush the pipeline
            // end
        end
    end

endmodule