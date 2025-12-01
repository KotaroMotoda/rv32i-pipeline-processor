# RV32I Pipeline Processor — Seminar Directory

A curated workspace for developing and presenting an educational RV32I processor design. This directory currently hosts a single-cycle implementation as a baseline, with a clear roadmap toward a 5-stage pipelined core targeting 120 MHz.

- Status: Single-cycle baseline ✅
- Goal: 5-stage pipeline (IF/ID/EX/MEM/WB) at 120 MHz 🎯
- ISA: RISC‑V RV32I

---

## Highlights

- Clean, education-friendly structure with focused modules
- Clear progression from single-cycle to pipelined microarchitecture
- FPGA-oriented folder for synthesis and board bring-up
- Sample programs for quick testing and demos

---

## Directory Layout

- [alu](https://github.com/KotaroMotoda/rv32i-pipeline-processor/tree/5c0d5218ed7736fc60042563b5a2a89e741a9ebd/seminor-dir/alu)
  - ALU-related logic and test collateral for arithmetic/logic operations.
- [riscv-np](https://github.com/KotaroMotoda/rv32i-pipeline-processor/tree/5c0d5218ed7736fc60042563b5a2a89e741a9ebd/seminor-dir/riscv-np)
  - [fpga](https://github.com/KotaroMotoda/rv32i-pipeline-processor/tree/5c0d5218ed7736fc60042563b5a2a89e741a9ebd/seminor-dir/riscv-np/fpga): Board/project files, constraints, and synthesis scripts.
  - [np](https://github.com/KotaroMotoda/rv32i-pipeline-processor/tree/5c0d5218ed7736fc60042563b5a2a89e741a9ebd/seminor-dir/riscv-np/np): Core logic for the processor (baseline and subsequent iterations).
  - [sample](https://github.com/KotaroMotoda/rv32i-pipeline-processor/tree/5c0d5218ed7736fc60042563b5a2a89e741a9ebd/seminor-dir/riscv-np/sample): Example programs for quick functional validation.

---

## Roadmap

- [x] Single-cycle RV32I baseline
- [x] 5-stage pipeline: IF, ID, EX, MEM, WB
- [x] Hazard detection and data forwarding
- [x] Control hazard handling (flush, basic prediction strategy optional)
- [x] Memory interface refinement and alignment rules
- [ ] Timing closure at 120 MHz (post-route on target FPGA)
- [ ] Documentation: microarchitecture diagrams and timing reports

---

## Technologies

- Hardware description: Verilog HDL (project-oriented toward FPGA synthesis)
- FPGA flow: Vendor toolchain (constraints/project under `riscv-np/fpga`)
- Test programs: RISC‑V assembly/C samples (under `riscv-np/sample`)
- Scripting/constraints: Typical use of XDC/Tcl or vendor equivalents in `fpga`

Note: Exact tool and file formats may vary by chosen FPGA vendor and board.

---

## Getting Started

1. Explore the baseline
   - Review the [alu](https://github.com/KotaroMotoda/rv32i-pipeline-processor/tree/5c0d5218ed7736fc60042563b5a2a89e741a9ebd/seminor-dir/alu) and [riscv-np/np](https://github.com/KotaroMotoda/rv32i-pipeline-processor/tree/5c0d5218ed7736fc60042563b5a2a89e741a9ebd/seminor-dir/riscv-np/np) modules to understand the single-cycle core.
2. Simulate
   - Use a Verilog‑2001–compliant simulator to validate ALU and core behavior.
3. Synthesize for FPGA
   - Open the project under [`riscv-np/fpga`](https://github.com/KotaroMotoda/rv32i-pipeline-processor/tree/5c0d5218ed7736fc60042563b5a2a89e741a9ebd/seminor-dir/riscv-np/fpga), apply board constraints, and build.
4. Run sample programs
   - Load binaries from [`riscv-np/sample`](https://github.com/KotaroMotoda/rv32i-pipeline-processor/tree/5c0d5218ed7736fc60042563b5a2a89e741a9ebd/seminor-dir/riscv-np/sample) to verify instruction execution and basic I/O.

---

## Design Principles

- Clarity first: prioritize readable RTL and modular structure
- Measurable progress: validate each stage (functionally and with timing)
- Hardware realism: close timing on real FPGA targets, not just simulation
- Reproducibility: keep constraints and project scripts version-controlled

---

## Contributing

Contributions that improve clarity, correctness, timing, or documentation are welcome.
- Add focused tests for ALU and pipeline hazards
- Share timing reports and optimization notes toward the 120 MHz goal
- Expand sample programs for coverage and demos

Please follow the repository’s style and submit concise, well‑scoped changes.

---

## License

This directory follows the license of the repository. See the LICENSE file at the repository root.

---

Crafted with care to be both instructional and practical—aimed at a clean path from a single-cycle baseline to a robust, 5-stage pipelined RV32I core running at 120 MHz.
