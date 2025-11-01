// filepath: /Users/motodakoutaroukari/Documents/workspace/github.com/KotaroMotoda/rv32i-pipeline-processor/seminor-dir/riscv-np/np/shift.v
module shift (
    input [31:0] data_in,
    input [4:0] shift_amount,
    input shift_type, // 0 for logical shift, 1 for arithmetic shift
    output reg [31:0] data_out
);
    always @(*) begin
        if (shift_type == 0) begin
            // Logical shift
            data_out = data_in >> shift_amount;
        end else begin
            // Arithmetic shift
            data_out = $signed(data_in) >>> shift_amount;
        end
    end
endmodule