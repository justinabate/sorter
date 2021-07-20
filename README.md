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
