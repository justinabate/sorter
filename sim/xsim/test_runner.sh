#!/bin/bash -f
#*********************************************************************************************************
#
# usage: test_runner.sh [-help]
# usage: test_runner.sh [-lib_map_path]
# usage: test_runner.sh [-noclean_files]
# usage: test_runner.sh [-reset_run]
#
#*********************************************************************************************************

DUT="sorter_tb"

# Command line options
xv_boost_lib_path=/opt/xlnx/Vivado/2019.2/tps/boost_1_64_0
xvlog_opts="--relax"
xvhdl_opts="--relax"


# Compile design files
compile()
{
  xvlog $xvlog_opts -prj ./src/vlog.prj -log ./logs/log_01_xvlog.log
  xvhdl $xvhdl_opts -prj ./src/vhdl.prj -log ./logs/log_02_xvhdl.log
}

elaborate()
{
  xelab --relax --debug typical --mt auto -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot sorter_tb xil_defaultlib.sorter_tb xil_defaultlib.glbl -log ./logs/log_03_xelab.log
}

simulate()
{
  xsim sorter_tb -gui -key {Behavioral:sim_1:Functional:sorter_tb} -tclbatch ./src/cmd.tcl -log ./logs/log_04_xsim.log
}

# STEP: setup
setup()
{
  case $1 in
    "-lib_map_path" )
      if [[ ($2 == "") ]]; then
        echo -e "ERROR: Simulation library directory path not specified (type \"./sorter_tb.sh -help\" for more information)\n"
        exit 1
      fi
    ;;
    "-reset_run" )
      reset_run
      echo -e "INFO: Simulation run files deleted.\n"
      exit 0
    ;;
    "-noclean_files" )
      # do not remove previous data
    ;;
    * )
  esac
}


cleanup()
{
  rm -rf .Xil/ xsim.dir/
#  find ./ -maxdepth 1 -type f -name "*.log" -exec mv {} logs/ \;
  find . -maxdepth 1 -type f -name "*.pb" -delete
  find . -maxdepth 1 -type f -name "*.log" -delete
  find . -maxdepth 1 -type f -name "*.jou" -delete
  find . -maxdepth 1 -type f -name "*.wdb" -delete
  find . -maxdepth 1 -type f -name "*.str" -delete

}

# Delete generated data from the previous run
# reset_run()
# {
#   files_to_remove=(xelab.pb xsim.jou xvhdl.log xvlog.log compile.log elaborate.log simulate.log xelab.log xsim.log run.log xvhdl.pb xvlog.pb sorter_tb.wdb xsim.dir)
#   for (( i=0; i<${#files_to_remove[*]}; i++ )); do
#     file="${files_to_remove[i]}"
#     if [[ -e $file ]]; then
#       rm -rf $file
#     fi
#   done
#   rm -rf logs/
# }



# Check command line arguments
check_args()
{
  if [[ ($1 == 1 ) && ($2 != "-lib_map_path" && $2 != "-noclean_files" && $2 != "-reset_run" && $2 != "-help" && $2 != "-h") ]]; then
    echo -e "ERROR: Unknown option specified '$2' (type \"./sorter_tb.sh -help\" for more information)\n"
    exit 1
  fi

  if [[ ($2 == "-help" || $2 == "-h") ]]; then
    usage
  fi
}

# Script usage
usage()
{
  msg="Usage: sorter_tb.sh [-help]\n\
Usage: sorter_tb.sh [-lib_map_path]\n\
Usage: sorter_tb.sh [-reset_run]\n\
Usage: sorter_tb.sh [-noclean_files]\n\n\
[-help] -- Print help information for this script\n\n\
[-lib_map_path <path>] -- Compiled simulation library directory path. The simulation library is compiled\n\
using the compile_simlib tcl command. Please see 'compile_simlib -help' for more information.\n\n\
[-reset_run] -- Recreate simulator setup files and library mappings for a clean run. The generated files\n\
from the previous run will be removed. If you don't want to remove the simulator generated files, use the\n\
-noclean_files switch.\n\n\
[-noclean_files] -- Reset previous run, but do not remove simulator generated files from the previous run.\n\n"
  echo -e $msg
  exit 1
}


# Main steps
run()
{
  check_args $# $1
  setup $1 $2
  mkdir -p logs/
  compile
  elaborate
  simulate
  cleanup
}


# Launch script
echo -e ">>>>> test_runner.sh via Vivado Xsim export_simulation"
run $1 $2