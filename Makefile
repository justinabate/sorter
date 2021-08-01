#!/usr/bin/make

XLNX_BIN=/opt/Xilinx/Vivado/2021.1/bin
VSIM_BIN=/opt/altera/20.1/modelsim_ase/linuxaloem
TB=sorter_tb
xv_boost_lib_path=/opt/xlnx/Vivado/2021.1/tps/boost_1_64_0
xvlog_opts=--relax
xvhdl_opts=--relax
xelab_opts=--relax --debug typical --mt auto -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot $(TB) xil_defaultlib.$(TB) xil_defaultlib.glbl
xsim_opts=-key {Behavioral:sim_1:Functional:$(TB)} -gui
#xsim_opts=-key {Behavioral:sim_1:Functional:$(TB)}

.DEFAULT_GOAL := ivl

.PHONY: clean vsim xsim

.ONESHELL:

clean:
	@rm -rf build/
	@cd sim/xsim
#	@rm -rf !(test_runner.sh|src)
	@rm -rf .Xil/ xsim.dir/ logs/
	@find . -maxdepth 1 -type f -name "*.pb" -delete
	@find . -maxdepth 1 -type f -name "*.log" -delete
	@find . -maxdepth 1 -type f -name "*.jou" -delete
	@find . -maxdepth 1 -type f -name "*.wdb" -delete
	@find . -maxdepth 1 -type f -name "*.str" -delete
	@cd ../vsim
	@rm -rf work transcript


vsim: clean
	@export PATH=$(VSIM_BIN):$$PATH
	@cd sim/vsim
	@vcom -2008 -work work ../../hdl/behav/$(TB).vhd
	@vsim -batch work.$(TB) -t 1fs -do src/run.do


xsim: clean
	@export PATH=$(XLNX_BIN):$$PATH
	@cd sim/xsim
	@mkdir -p logs
	@xvlog $(xvlog_opts) -prj ./src/vlog.prj -log ./logs/log_01_xvlog.log
	@xvhdl $(xvhdl_opts) -prj ./src/vhdl.prj -log ./logs/log_02_xvhdl.log
	@xelab $(xelab_opts) -log ./logs/log_03_xelab.log
	@xsim $(TB) $(xsim_opts) -tclbatch ./src/cmd.tcl -log ./logs/log_04_xsim.log


