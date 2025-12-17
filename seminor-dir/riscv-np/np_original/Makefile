SRC = tb.v riscv.v rf.v alu.v shift.v dmem.v daligner.v if_stage.v id_stage.v pipeline_regs.v ex_stage.v mem_stage.v wb_stage.v hazard_detection_unit.v forwarding_unit.v riscv_core.v clk_wiz_0.v clk_wiz_0_clk_wiz.v

iverilog:
	iverilog $(SRC) -o riscv

clean:
	$(RM) *~ riscv riscv.vcd *.log