create_project riscv ./riscv -part xc7a100tcsg324-1 -force
set_property board_part digilentinc.com:nexys4_ddr:part0:1.1 [current_project]
import_files -norecurse {../np/riscv.v ../np/riscv.vh ../np/inst.vh ../np/alu.vh ../np/alu.v  ../np/daligner.v  ../np/dmem.v ../np/rf.v ../np/shift.v ../np/prog.mif ../np/data.mif }
update_compile_order -fileset sources_1
add_files -fileset constrs_1 -norecurse ./riscv.xdc
import_files -fileset constrs_1 ./riscv.xdc
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
exit
