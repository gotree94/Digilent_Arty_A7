# ============================================================================
# Arty A7 DDR3L Controller Project Setup
# Vivado TCL Script
# ============================================================================

# Create project
create_project ddr3l_controller ./ddr3l_project -part xc7a35ticsg324-1L

# Add source files
add_files -norecurse {
    ./rtl/ddr3l_controller.v
    ./rtl/ddr3_init_controller.v
    ./rtl/ddr3_cmd_scheduler.v
}

# Add testbench files
add_files -fileset sim_1 -norecurse {
    ./tb/tb_ddr3l_controller.v
    ./tb/ddr3_model.v
}

# Add constraint files
add_files -fileset constrs_1 -norecurse ./constraints/arty_a7_ddr3.xdc

# Set top module
set_property top ddr3l_controller [current_fileset]
set_property top tb_ddr3l_controller [get_filesets sim_1]

# ============================================================================
# Arty A7 DDR3L Constraints (XDC File)
# File: arty_a7_ddr3.xdc
# ============================================================================

## Clock Constraints
create_clock -period 5.000 -name clk_200mhz -waveform {0.000 2.500} [get_ports clk_200mhz]
create_clock -period 10.000 -name clk_100mhz -waveform {0.000 5.000} [get_ports clk_100mhz]

## Input Delay Constraints
set_input_delay -clock clk_100mhz -min 1.000 [get_ports {user_addr[*] user_wdata[*] user_rd_req user_wr_req user_mask[*]}]
set_input_delay -clock clk_100mhz -max 8.000 [get_ports {user_addr[*] user_wdata[*] user_rd_req user_wr_req user_mask[*]}]

## Output Delay Constraints  
set_output_delay -clock clk_100mhz -min 0.000 [get_ports {user_rdata[*] user_rd_valid user_ready}]
set_output_delay -clock clk_100mhz -max 5.000 [get_ports {user_rdata[*] user_rd_valid user_ready}]

## Reset Pin
set_property PACKAGE_PIN C2 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]

## Clock Pins (from Arty A7 schematic)
set_property PACKAGE_PIN E3 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]

## DDR3L Memory Interface Pins

# Clock
set_property PACKAGE_PIN U9 [get_ports ddr3_ck_p]
set_property PACKAGE_PIN V9 [get_ports ddr3_ck_n]
set_property IOSTANDARD DIFF_SSTL135 [get_ports ddr3_ck_p]
set_property IOSTANDARD DIFF_SSTL135 [get_ports ddr3_ck_n]

# Control Signals
set_property PACKAGE_PIN P2 [get_ports ddr3_cke]
set_property PACKAGE_PIN P3 [get_ports ddr3_cs_n]
set_property PACKAGE_PIN K6 [get_ports ddr3_ras_n]
set_property PACKAGE_PIN L1 [get_ports ddr3_cas_n]
set_property PACKAGE_PIN L4 [get_ports ddr3_we_n]
set_property PACKAGE_PIN K3 [get_ports ddr3_reset_n]
set_property PACKAGE_PIN N5 [get_ports ddr3_odt]

set_property IOSTANDARD SSTL135 [get_ports ddr3_cke]
set_property IOSTANDARD SSTL135 [get_ports ddr3_cs_n]
set_property IOSTANDARD SSTL135 [get_ports ddr3_ras_n]
set_property IOSTANDARD SSTL135 [get_ports ddr3_cas_n]
set_property IOSTANDARD SSTL135 [get_ports ddr3_we_n]
set_property IOSTANDARD SSTL135 [get_ports ddr3_reset_n]
set_property IOSTANDARD SSTL135 [get_ports ddr3_odt]

# Bank Address
set_property PACKAGE_PIN P5 [get_ports {ddr3_ba[0]}]
set_property PACKAGE_PIN P4 [get_ports {ddr3_ba[1]}]
set_property PACKAGE_PIN R1 [get_ports {ddr3_ba[2]}]
set_property IOSTANDARD SSTL135 [get_ports {ddr3_ba[*]}]

# Address
set_property PACKAGE_PIN N4 [get_ports {ddr3_addr[0]}]
set_property PACKAGE_PIN T1 [get_ports {ddr3_addr[1]}]
set_property PACKAGE_PIN N6 [get_ports {ddr3_addr[2]}]
set_property PACKAGE_PIN T6 [get_ports {ddr3_addr[3]}]
set_property PACKAGE_PIN R7 [get_ports {ddr3_addr[4]}]
set_property PACKAGE_PIN V6 [get_ports {ddr3_addr[5]}]
set_property PACKAGE_PIN U7 [get_ports {ddr3_addr[6]}]
set_property PACKAGE_PIN R8 [get_ports {ddr3_addr[7]}]
set_property PACKAGE_PIN V7 [get_ports {ddr3_addr[8]}]
set_property PACKAGE_PIN R6 [get_ports {ddr3_addr[9]}]
set_property PACKAGE_PIN U6 [get_ports {ddr3_addr[10]}]
set_property PACKAGE_PIN T5 [get_ports {ddr3_addr[11]}]
set_property PACKAGE_PIN U5 [get_ports {ddr3_addr[12]}]
set_property PACKAGE_PIN R5 [get_ports {ddr3_addr[13]}]
set_property IOSTANDARD SSTL135 [get_ports {ddr3_addr[*]}]

# Data
set_property PACKAGE_PIN K5 [get_ports {ddr3_dq[0]}]
set_property PACKAGE_PIN L3 [get_ports {ddr3_dq[1]}]
set_property PACKAGE_PIN K3 [get_ports {ddr3_dq[2]}]
set_property PACKAGE_PIN L6 [get_ports {ddr3_dq[3]}]
set_property PACKAGE_PIN M3 [get_ports {ddr3_dq[4]}]
set_property PACKAGE_PIN M6 [get_ports {ddr3_dq[5]}]
set_property PACKAGE_PIN L4 [get_ports {ddr3_dq[6]}]
set_property PACKAGE_PIN M4 [get_ports {ddr3_dq[7]}]
set_property PACKAGE_PIN N1 [get_ports {ddr3_dq[8]}]
set_property PACKAGE_PIN L5 [get_ports {ddr3_dq[9]}]
set_property PACKAGE_PIN N2 [get_ports {ddr3_dq[10]}]
set_property PACKAGE_PIN N3 [get_ports {ddr3_dq[11]}]
set_property PACKAGE_PIN T8 [get_ports {ddr3_dq[12]}]
set_property PACKAGE_PIN T7 [get_ports {ddr3_dq[13]}]
set_property PACKAGE_PIN N7 [get_ports {ddr3_dq[14]}]
set_property PACKAGE_PIN M7 [get_ports {ddr3_dq[15]}]
set_property IOSTANDARD SSTL135 [get_ports {ddr3_dq[*]}]

# Data Strobe
set_property PACKAGE_PIN L2 [get_ports {ddr3_dqs_p[0]}]
set_property PACKAGE_PIN K1 [get_ports {ddr3_dqs_n[0]}]
set_property PACKAGE_PIN U8 [get_ports {ddr3_dqs_p[1]}]
set_property PACKAGE_PIN V8 [get_ports {ddr3_dqs_n[1]}]
set_property IOSTANDARD DIFF_SSTL135 [get_ports {ddr3_dqs_p[*]}]
set_property IOSTANDARD DIFF_SSTL135 [get_ports {ddr3_dqs_n[*]}]

# Data Mask
set_property PACKAGE_PIN K4 [get_ports {ddr3_dm[0]}]
set_property PACKAGE_PIN M1 [get_ports {ddr3_dm[1]}]
set_property IOSTANDARD SSTL135 [get_ports {ddr3_dm[*]}]

## Timing Constraints for DDR3L

# Clock period constraint
set_property CLOCK_DEDICATED_ROUTE BACKBONE [get_nets clk_100mhz]

# DDR3L timing constraints
create_generated_clock -name ddr3_ck -source [get_ports clk_200mhz] -divide_by 1 [get_ports ddr3_ck_p]

# Input/Output delays for DDR3L interface
set tco_min 0.2
set tco_max 0.8
set tsu 0.1
set th 0.1

set_output_delay -clock ddr3_ck -min $tco_min [get_ports {ddr3_addr[*] ddr3_ba[*] ddr3_ras_n ddr3_cas_n ddr3_we_n ddr3_cke ddr3_cs_n ddr3_odt}]
set_output_delay -clock ddr3_ck -max $tco_max [get_ports {ddr3_addr[*] ddr3_ba[*] ddr3_ras_n ddr3_cas_n ddr3_we_n ddr3_cke ddr3_cs_n ddr3_odt}]

# Write data timing
set_output_delay -clock ddr3_ck -min $tco_min [get_ports {ddr3_dq[*] ddr3_dm[*]}]
set_output_delay -clock ddr3_ck -max $tco_max [get_ports {ddr3_dq[*] ddr3_dm[*]}]

# Read data timing
set_input_delay -clock ddr3_ck -min $tsu [get_ports {ddr3_dq[*]}]
set_input_delay -clock ddr3_ck -max $th [get_ports {ddr3_dq[*]}]

# False paths for asynchronous reset
set_false_path -from [get_ports rst_n]
set_false_path -to [get_ports ddr3_reset_n]

# Multi-cycle paths for initialization
set_multicycle_path -setup 2 -from [get_clocks clk_100mhz] -to [get_clocks ddr3_ck]
set_multicycle_path -hold 1 -from [get_clocks clk_100mhz] -to [get_clocks ddr3_ck]

## Physical Constraints

# Placement constraints for DDR3L interface
set_property LOC PHASER_OUT_PHY_X1Y1 [get_cells -hierarchical -filter {NAME =~ *phaser_out*}]

# IO Buffer placement
set_property INTERNAL_VREF 0.675 [get_iobanks 35]

## Configuration Constraints
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# ============================================================================
# Makefile for DDR3L Controller Project
# ============================================================================

## Makefile
.PHONY: all clean sim synth impl program

PROJECT_NAME = ddr3l_controller
TOP_MODULE = ddr3l_controller
TB_MODULE = tb_ddr3l_controller

# Vivado settings
VIVADO = vivado
VIVADO_BATCH = $(VIVADO) -mode batch -source

# Directories
RTL_DIR = rtl
TB_DIR = tb
CONSTRAINT_DIR = constraints
BUILD_DIR = build

# Source files
RTL_SOURCES = $(wildcard $(RTL_DIR)/*.v)
TB_SOURCES = $(wildcard $(TB_DIR)/*.v)
XDC_FILES = $(wildcard $(CONSTRAINT_DIR)/*.xdc)

all: impl

# Create project
project:
	@echo "Creating Vivado project..."
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && $(VIVADO) -mode batch -source ../scripts/create_project.tcl

# Run simulation
sim:
	@echo "Running simulation..."
	@cd $(BUILD_DIR) && $(VIVADO_BATCH) ../scripts/run_sim.tcl

# Run synthesis
synth:
	@echo "Running synthesis..."
	@cd $(BUILD_DIR) && $(VIVADO_BATCH) ../scripts/run_synth.tcl

# Run implementation
impl:
	@echo "Running implementation..."
	@cd $(BUILD_DIR) && $(VIVADO_BATCH) ../scripts/run_impl.tcl

# Generate bitstream
bitstream:
	@echo "Generating bitstream..."
	@cd $(BUILD_DIR) && $(VIVADO_BATCH) ../scripts/gen_bitstream.tcl

# Program FPGA
program:
	@echo "Programming FPGA..."
	@cd $(BUILD_DIR) && $(VIVADO_BATCH) ../scripts/program_fpga.tcl

# Clean build directory
clean:
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)
	@rm -f *.log *.jou

# ============================================================================
# TCL Scripts for Automation
# ============================================================================

## Script: create_project.tcl
# Create new project
create_project $(PROJECT_NAME) . -part xc7a35ticsg324-1L -force

# Add source files
add_files -norecurse ../$(RTL_DIR)/ddr3l_controller.v
add_files -norecurse ../$(RTL_DIR)/ddr3_init_controller.v  
add_files -norecurse ../$(RTL_DIR)/ddr3_cmd_scheduler.v

# Add testbench
add_files -fileset sim_1 -norecurse ../$(TB_DIR)/tb_ddr3l_controller.v

# Add constraints
add_files -fileset constrs_1 -norecurse ../$(CONSTRAINT_DIR)/arty_a7_ddr3.xdc

# Set top modules
set_property top $(TOP_MODULE) [current_fileset]
set_property top $(TB_MODULE) [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

close_project

## Script: run_sim.tcl
open_project $(PROJECT_NAME).xpr

# Set simulation properties
set_property -name {xsim.simulate.runtime} -value {100us} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

# Launch simulation
launch_simulation
run all

close_project

## Script: run_synth.tcl
open_project $(PROJECT_NAME).xpr

# Reset previous runs
reset_run synth_1

# Launch synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Open synthesized design
open_run synth_1 -name synth_1

# Generate reports
report_timing_summary -file timing_synth.rpt
report_utilization -file utilization_synth.rpt
report_power -file power_synth.rpt

close_project

## Script: run_impl.tcl
open_project $(PROJECT_NAME).xpr

# Reset previous runs
reset_run impl_1

# Launch implementation
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Open implemented design
open_run impl_1 -name impl_1

# Generate reports
report_timing_summary -file timing_impl.rpt
report_utilization -file utilization_impl.rpt
report_route_status -file route_status.rpt
report_drc -file drc.rpt
report_power -file power_impl.rpt

# Check timing
if {[get_property SLACK [get_timing_paths]] < 0} {
    puts "ERROR: Timing constraints not met!"
    exit 1
} else {
    puts "INFO: Timing constraints met."
}

close_project

## Script: gen_bitstream.tcl
open_project $(PROJECT_NAME).xpr

# Generate bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

close_project

## Script: program_fpga.tcl
open_project $(PROJECT_NAME).xpr

# Open hardware manager
open_hw_manager
connect_hw_server
open_hw_target

# Program device
current_hw_device [get_hw_devices xc7a35t_0]
set_property PROGRAM.FILE {./ddr3l_controller.runs/impl_1/ddr3l_controller.bit} [get_hw_devices xc7a35t_0]
program_hw_devices [get_hw_devices xc7a35t_0]

close_hw_manager
close_project

# ============================================================================
# Project Directory Structure
# ============================================================================

## Directory structure should be:
# ddr3l_project/
# ├── rtl/
# │   ├── ddr3l_controller.v
# │   ├── ddr3_init_controller.v
# │   └── ddr3_cmd_scheduler.v
# ├── tb/
# │   └── tb_ddr3l_controller.v
# ├── constraints/
# │   └── arty_a7_ddr3.xdc
# ├── scripts/
# │   ├── create_project.tcl
# │   ├── run_sim.tcl
# │   ├── run_synth.tcl
# │   ├── run_impl.tcl
# │   ├── gen_bitstream.tcl
# │   └── program_fpga.tcl
# ├── build/
# │   └── (generated files)
# ├── docs/
# │   ├── README.md
# │   └── timing_analysis.md
# └── Makefile

# ============================================================================
# README.md Content
# ============================================================================

## README.md
# DDR3L Memory Controller for Arty A7

This project implements a DDR3L memory controller specifically designed for the Digilent Arty A7 FPGA development board.

## Features

- Full DDR3L-1600 support (MT41K128M16JT-125)
- AXI4 compatible user interface
- Automatic initialization sequence
- Refresh management
- Multi-bank operation with conflict avoidance
- Comprehensive testbench with multiple test patterns

## Getting Started

### Prerequisites

- Xilinx Vivado 2020.1 or later
- Digilent Arty A7-35T or A7-100T board
- USB cable for programming

### Build Instructions

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd ddr3l_project
   ```

2. Create Vivado project:
   ```bash
   make project
   ```

3. Run simulation:
   ```bash
   make sim
   ```

4. Run synthesis and implementation:
   ```bash
   make impl
   ```

5. Generate bitstream:
   ```bash
   make bitstream
   ```

6. Program FPGA:
   ```bash
   make program
   ```

## Module Hierarchy

- `ddr3l_controller` - Top level controller
  - `ddr3_init_controller` - Initialization sequence controller
  - `ddr3_cmd_scheduler` - Command scheduler with bank management
  - Clock generation and management
  - Data path controllers

## Interface Signals

### User Interface
- `user_addr[26:0]` - 27-bit address (128MB address space)
- `user_wdata[127:0]` - 128-bit write data
- `user_rdata[127:0]` - 128-bit read data
- `user_rd_req` - Read request
- `user_wr_req` - Write request
- `user_mask[15:0]` - Byte write mask
- `user_rd_valid` - Read data valid
- `user_ready` - Controller ready for new requests

### DDR3L Physical Interface
- Clock: `ddr3_ck_p/n`
- Control: `ddr3_cke`, `ddr3_cs_n`, `ddr3_ras_n`, `ddr3_cas_n`, `ddr3_we_n`
- Address: `ddr3_addr[13:0]`, `ddr3_ba[2:0]`
- Data: `ddr3_dq[15:0]`, `ddr3_dqs_p/n[1:0]`, `ddr3_dm[1:0]`
- Power: `ddr3_odt`, `ddr3_reset_n`

## Testing

The testbench includes the following test cases:

1. **Initialization Test** - Verifies proper DDR3L initialization sequence
2. **Basic R/W Test** - Simple read/write operations
3. **Burst Test** - Sequential burst operations
4. **Random Test** - Random address access patterns
5. **Walking Ones/Zeros** - Data integrity tests
6. **Performance Test** - Bandwidth and latency measurements

## Performance

Expected performance on Arty A7:
- Clock frequency: 200 MHz DDR3L (400 MT/s)
- Theoretical bandwidth: 800 MB/s
- Typical achieved bandwidth: ~600 MB/s
- Read latency: 15-20 clock cycles

## Timing Analysis

Critical timing paths:
- Clock domain crossing between user and DDR3L domains
- Data capture from DDR3L DQS signals
- Command setup and hold times

## Known Limitations

1. No ECC support
2. Simplified refresh scheduling
3. Single port interface
4. No power management features

## Future Enhancements

- ECC implementation
- Multi-port interface
- Advanced refresh algorithms
- Power optimization
- DDR4 support

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Support

For questions and support, please open an issue on the project repository.
