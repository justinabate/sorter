[//]: # (call to https://shields.io/endpoint)
[![Jenkins vsim](https://img.shields.io/badge/dynamic/json.svg?label=vsim&url=https://raw.githubusercontent.com/justinabate/sorter/master/jenkins/badges.json&query=vsim&colorB=success)](https://github.com/justinabate/sorter/commits/master)
[![Git Commits](https://img.shields.io/badge/dynamic/json.svg?label=commits&url=https://raw.githubusercontent.com/justinabate/sorter/master/jenkins/badges.json&query=commits&colorB=brightgreen)](https://github.com/justinabate/sorter/commits/master)


# sorter
Verilog implementation of an AXIS number sorter


To run:
```
cd sim/xsim
./test_runner.sh
```

The sorter module receives four numbers from the AXIS bus and presents them on output ports lvl1, lvl2, lvl3, and lvl4, where level 1 is the largest value and level 4 is the smallest value. A done flag is asserted when lvl1-4 are valid.


Simulatuion passed with DATA_WIDTH 16, 32, and 64. 


: Vivado 2019.2 on Ubuntu 18.04.4 LTS

