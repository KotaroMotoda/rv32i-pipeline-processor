# RISC-V Pipeline Processor Project

This project implements a RISC-V pipeline processor using Verilog. The design is structured into multiple stages, each responsible for a specific part of the instruction processing flow. Below is a brief description of each component in the project.

## Project Structure

- **if_stage.v**: Implements the Instruction Fetch (IF) stage. Manages the program counter (PC) and fetches instructions from instruction memory.

- **id_stage.v**: Implements the Instruction Decode (ID) stage. Responsible for decoding instructions, retrieving data from the register file, and generating control signals.

- **ex_stage.v**: Implements the Execute (EX) stage. Performs arithmetic and logical operations using the ALU and generates results.

- **mem_stage.v**: Implements the Memory Access (MEM) stage. Handles access to data memory and controls read/write operations.

- **wb_stage.v**: Implements the Write Back (WB) stage. Writes back ALU results or data from memory to the register file.

- **pipeline_regs.v**: Defines registers between each pipeline stage. Manages IF/ID, ID/EX, EX/MEM, and MEM/WB registers.

- **control_unit.v**: Implements the control unit. Generates control signals based on instructions to manage the operation of each stage.

- **branch_unit.v**: Implements the branch unit. Handles branch instruction processing and controls PC updates.

- **hazard_unit.v**: Implements the hazard unit. Detects data hazards and control hazards, flushing or stalling the pipeline as necessary.

- **imem.v**: Implements instruction memory. Reads instructions from program memory.

- **riscv_top.v**: The top-level module that instantiates each stage and unit, managing the overall flow of the processor.

- **riscv_full.v**: Integrates all components and defines the overall operation of the pipeline.

## Usage

To simulate the RISC-V pipeline processor, ensure that all Verilog files are included in your simulation environment. You can modify the testbench to provide different instruction sequences and observe the behavior of the pipeline stages.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.