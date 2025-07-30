# ALU Verification Project

## Overview

This project implements a comprehensive SystemVerilog verification environment for an Arithmetic Logic Unit (ALU) design. The ALU is a parameterized 8-bit processor core component that performs both arithmetic and logical operations with advanced features including overflow detection, comparison flags, and clock enable control.

## File Structure
```
ALU_TB/
├── README.md
├── docs/                               # Documentation
├── src/
│   ├── design/
│   │   └── alu_design.sv               # ALU RTL implementation
│   └── tb/                             # Testbench files
│       ├── alu_assertions.sv           # SystemVerilog assertions
│       ├── alu_bind.sv                 # Assertion binding
│       ├── alu_driver.sv               # Driver class
│       ├── alu_environment.sv          # Environment class
│       ├── alu_generator.sv            # Transaction generator
│       ├── alu_if.sv                   # Interface definition
│       ├── alu_monitor.sv              # Monitor class
│       ├── alu_pkg.sv                  # Package definition
│       ├── alu_reference_model.sv      # Golden reference
│       ├── alu_scoreboard.sv           # Scoreboard for checking
│       ├── alu_test.sv                 # Test classes
│       ├── alu_top.v                   # Verilog top module
│       ├── alu_transaction.sv          # Transaction class
│       ├── defines.sv                  # Macro definitions
│       └── top.sv                      # SystemVerilog top module
```

### Quick Start
1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd ALU/src_v1/ALU_TB
   ```

2. **Compile and run**:
   ```bash
    vlog -sv +acc +cover +fcover -l alu.log top.sv
    vsim -vopt top -voptargs=+acc=npr -assertdebug -l simulation.log -coverage -c -do "coverage save -onexit -assert -directive -cvg -codeAll coverage.ucdb; run -all; exit"
    vcover report -html coverage.ucdb -htmldir covReport -details
   ```

3. **View results**:
   - Check simulation transcript for pass/fail status
   - Open coverage reports in `covReport/` directory
   - Review assertion results in simulation log

#### Parameter Configuration
Modify `defines.sv` to customize:
```systemverilog
`define OP_WIDTH 8        # Operand width (8/16/32)
`define CMD_WIDTH 4       # Command width
`define no_of_trans 150  # Number of test transactions
```

## Verification Metrics

The testbench provides comprehensive metrics including:
- **Transaction Statistics**: Pass/fail ratios
- **Coverage Reports**: Functional and code coverage percentages
- **Assertion Reports**: Specification compliance verification
