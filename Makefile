FLAGS = --std=08 -P../OsvvmLibraries/sim_ghdl/VHDL_LIBS/GHDL-5.0.0-dev
dut=convenc
sequencer=TestCtrl_e
test_harness=TbStream
test_case=TbStream_SendGet1
utils = TestbenchUtilsPkg
stop_time = 50us

all:
	# 'analysis'
	ghdl -a ${FLAGS} ${utils}.vhd ${dut}.vhd ${sequencer}.vhd ${test_harness}.vhd ${test_case}.vhd 

	# 'elaborate'
	ghdl -e ${FLAGS} ${test_harness}

	# 'run'
	ghdl -r ${FLAGS} ${test_harness} --vcd=${test_case}.vcd --stop-time=${stop_time}

view:
	gtkwave ${test_case}.vcd

clean:
	rm -f *.cf *.ghw *.vcd
