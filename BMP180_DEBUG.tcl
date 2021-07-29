# Copyright (C) 2018  Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License 
# Subscription Agreement, the Intel Quartus Prime License Agreement,
# the Intel FPGA IP License Agreement, or other applicable license
# agreement, including, without limitation, that your use is for
# the sole purpose of programming logic devices manufactured by
# Intel and sold by Intel or its authorized distributors.  Please
# refer to the applicable agreement for further details.

# Quartus Prime: Generate Tcl File for Project
# File: BMP180_DEBUG.tcl
# Generated on: Thu Jul 29 14:37:03 2021

# Load Quartus Prime Tcl Project package
package require ::quartus::project

set need_to_close_project 0
set make_assignments 1

# Check that the right project is open
if {[is_project_open]} {
	if {[string compare $quartus(project) "BMP180"]} {
		puts "Project BMP180 is not open"
		set make_assignments 0
	}
} else {
	# Only open if not already open
	if {[project_exists BMP180]} {
		project_open -revision BMP180 BMP180
	} else {
		project_new -revision BMP180 BMP180
	}
	set need_to_close_project 1
}

# Make assignments
if {$make_assignments} {
	set_global_assignment -name FAMILY "Cyclone V"
	set_global_assignment -name DEVICE 5CSEMA5F31C6
	set_global_assignment -name TOP_LEVEL_ENTITY BMP180_DEBUG
	set_global_assignment -name ORIGINAL_QUARTUS_VERSION 18.1.0
	set_global_assignment -name PROJECT_CREATION_TIME_DATE "12:47:21  MAY 31, 2021"
	set_global_assignment -name LAST_QUARTUS_VERSION "18.1.0 Lite Edition"
	set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files
	set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
	set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
	set_global_assignment -name ERROR_CHECK_FREQUENCY_DIVISOR 256
	set_global_assignment -name EDA_SIMULATION_TOOL "ModelSim-Altera (Verilog)"
	set_global_assignment -name EDA_TIME_SCALE "1 ps" -section_id eda_simulation
	set_global_assignment -name EDA_OUTPUT_DATA_FORMAT "VERILOG HDL" -section_id eda_simulation
	set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
	set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
	set_global_assignment -name TIMING_ANALYZER_MULTICORNER_ANALYSIS ON
	set_global_assignment -name NUM_PARALLEL_PROCESSORS ALL
	set_global_assignment -name EDA_TEST_BENCH_ENABLE_STATUS TEST_BENCH_MODE -section_id eda_simulation
	set_global_assignment -name EDA_NATIVELINK_SIMULATION_TEST_BENCH div_vlg_tst -section_id eda_simulation
	set_global_assignment -name EDA_TEST_BENCH_NAME BMP180_vlg_tst -section_id eda_simulation
	set_global_assignment -name EDA_DESIGN_INSTANCE_NAME NA -section_id BMP180_vlg_tst
	set_global_assignment -name EDA_TEST_BENCH_MODULE_NAME BMP180_vlg_tst -section_id BMP180_vlg_tst
	set_global_assignment -name BOARD "DE1-SoC Board"
	set_global_assignment -name OPTIMIZATION_MODE "AGGRESSIVE PERFORMANCE"
	set_global_assignment -name ENABLE_SIGNALTAP ON
	set_global_assignment -name USE_SIGNALTAP_FILE output_files/stp1.stp
	set_global_assignment -name EDA_TEST_BENCH_NAME i2c_master_vlg_tst -section_id eda_simulation
	set_global_assignment -name EDA_DESIGN_INSTANCE_NAME NA -section_id i2c_master_vlg_tst
	set_global_assignment -name EDA_TEST_BENCH_MODULE_NAME i2c_master_vlg_tst -section_id i2c_master_vlg_tst
	set_global_assignment -name POWER_USE_INPUT_FILES OFF
	set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
	set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
	set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
	set_global_assignment -name VERILOG_FILE BMP180_DEBUG.v
	set_global_assignment -name VERILOG_FILE BMP180.v
	set_global_assignment -name VERILOG_FILE controller_fsm.v
	set_global_assignment -name VERILOG_FILE calc_fsm.v
	set_global_assignment -name VERILOG_FILE rom.v
	set_global_assignment -name VERILOG_FILE opm.v
	set_global_assignment -name VERILOG_FILE clk_div_msrmnt.v
	set_global_assignment -name VERILOG_FILE alu.v
	set_global_assignment -name VERILOG_FILE mult.v
	set_global_assignment -name VERILOG_FILE div.v
	set_global_assignment -name VERILOG_FILE i2c_master.v
	set_global_assignment -name VERILOG_FILE i2c_fsm.v
	set_global_assignment -name VERILOG_FILE i2c_clk_div.v
	set_global_assignment -name SDC_FILE BMP180_DEBUG.sdc
	set_global_assignment -name SDC_FILE BMP180.sdc
	set_global_assignment -name EDA_TEST_BENCH_FILE simulation/modelsim/BMP180.vt -section_id BMP180_vlg_tst
	set_global_assignment -name EDA_TEST_BENCH_FILE simulation/modelsim/i2c_master.vt -section_id i2c_master_vlg_tst
	set_global_assignment -name EDA_TEST_BENCH_NAME div_vlg_tst -section_id eda_simulation
	set_global_assignment -name EDA_DESIGN_INSTANCE_NAME NA -section_id div_vlg_tst
	set_global_assignment -name EDA_TEST_BENCH_MODULE_NAME div_vlg_tst -section_id div_vlg_tst
	set_global_assignment -name EDA_TEST_BENCH_FILE simulation/modelsim/div.vt -section_id div_vlg_tst
	set_global_assignment -name SLD_FILE db/stp1_auto_stripped.stp
	set_location_assignment PIN_AF14 -to CLK
	set_location_assignment PIN_AG18 -to IO_SCL
	set_location_assignment PIN_AJ21 -to IO_SDA
	set_location_assignment PIN_V16 -to O_LEDR[0]
	set_location_assignment PIN_W16 -to O_LEDR[1]
	set_location_assignment PIN_V17 -to O_LEDR[2]
	set_location_assignment PIN_V18 -to O_LEDR[3]
	set_location_assignment PIN_W17 -to O_LEDR[4]
	set_location_assignment PIN_W19 -to O_LEDR[5]
	set_location_assignment PIN_Y19 -to O_LEDR[6]
	set_location_assignment PIN_W20 -to O_LEDR[7]
	set_location_assignment PIN_AB12 -to I_SW[0]
	set_location_assignment PIN_AC12 -to I_SW[1]
	set_location_assignment PIN_AF9 -to I_SW[2]
	set_location_assignment PIN_AF10 -to I_SW[3]
	set_location_assignment PIN_AD11 -to I_SW[4]
	set_location_assignment PIN_AD12 -to I_SW[5]
	set_location_assignment PIN_AA14 -to I_KEY[0]
	set_location_assignment PIN_AA15 -to I_KEY[1]
	set_location_assignment PIN_AE11 -to I_SW[6]
	set_location_assignment PIN_W21 -to O_LEDR[8]
	set_location_assignment PIN_Y21 -to O_LEDR[9]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to IO_SDA
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to IO_SCL
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLK
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to O_LEDR[9]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to O_LEDR[8]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to O_LEDR[7]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to O_LEDR[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to O_LEDR[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to O_LEDR[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to O_LEDR[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to O_LEDR[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to O_LEDR[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to O_LEDR[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to I_SW[6]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to I_SW[5]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to I_SW[4]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to I_SW[3]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to I_SW[2]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to I_SW[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to I_SW[0]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to I_KEY[1]
	set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to I_KEY[0]
	set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top

	# Commit assignments
	export_assignments

	# Close project
	if {$need_to_close_project} {
		project_close
	}
}
