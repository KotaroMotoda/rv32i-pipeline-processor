SRC = tb.v riscv.v rf.v alu.v shift.v dmem.v daligner.v 

iverilog:
	iverilog $(SRC) -o riscv

clean:
	$(RM) *~ riscv riscv.vcd *.log
