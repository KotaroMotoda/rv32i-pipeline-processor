CPU ?= origin

# Select which CPU RTL to simulate:
#   origin  -> uses riscv_origin.v (matches tb.v expectations: dmem, daligner, signals)
#   current -> uses riscv.v (WIP/pipeline version; may not expose dmem etc.)
ifeq ($(CPU),origin)
	RISCV_TOP = riscv_origin.v
	DEFS = -DORIGIN
else
	RISCV_TOP = riscv.v
	DEFS = -DPIPELINE
endif

SRC = tb.v $(RISCV_TOP) rf.v alu.v shift.v dmem.v daligner.v 

iverilog:
	iverilog $(DEFS) $(SRC) -o riscv

clean:
	$(RM) *~ riscv riscv.vcd *.log
