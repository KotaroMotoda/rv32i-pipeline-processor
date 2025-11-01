module mem_stage
    (
        input CLK,
        input RST,
        input [31:0] WA_EM,
        input [31:0] WD_EM,
        input [31:0] MEM_DATA_M,
        input [1:0] MemWrite_EM,
        input [1:0] MemRead_EM,
        output reg [31:0] MEM_DATA_MW,
        output reg [31:0] WA_MW,
        output reg RegWrite_MW
    );

    // Memory declaration
    reg [31:0] dmem[0:32767]; // 32kW = 128kB

    // Memory initialization
    initial
    begin
        // Load data from data.mif or initialize memory
        $readmemh("data.mif", dmem);
    end

    // Memory access logic
    always @(posedge CLK or posedge RST)
    begin
        if (RST)
        begin
            MEM_DATA_MW <= 32'h00000000;
            WA_MW <= 32'h00000000;
            RegWrite_MW <= 1'b0;
        end
        else
        begin
            // Write operation
            if (MemWrite_EM != 2'b00)
            begin
                dmem[WA_EM[31:2]] <= WD_EM; // Store data in memory
            end

            // Read operation
            if (MemRead_EM != 2'b00)
            begin
                MEM_DATA_MW <= dmem[WA_EM[31:2]]; // Load data from memory
            end

            WA_MW <= WA_EM;
            RegWrite_MW <= (MemRead_EM != 2'b00) || (MemWrite_EM != 2'b00);
        end
    end

endmodule