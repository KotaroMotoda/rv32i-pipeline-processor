CPU ?= current

# Select which CPU RTL to simulate:
#   origin  -> uses riscv_origin.v (matches tb.v expectations: dmem, daligner, signals)
#   current -> uses riscv.v (WIP/pipeline version; may not expose dmem etc.)
ifeq ($(CPU),origin)
	RISCV_TOP = riscv.v
	DEFS = -DORIGIN
else
	RISCV_TOP = riscv.v
	DEFS = -DPIPELINE
endif

SRC = tb.v $(RISCV_TOP) rf.v alu.v shift.v dmem.v daligner.v if_stage.v id_stage.v pipeline_regs.v ex_stage.v mem_stage.v wb_stage.v

iverilog:
	iverilog $(DEFS) $(SRC) -o riscv

clean:
	$(RM) *~ riscv riscv.vcd *.log