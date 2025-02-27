FLAGS = --std=08 -P../OsvvmLibraries/sim_ghdl/VHDL_LIBS/GHDL-5.0.0-dev
project=convenc
design = $(project).vhd 
test = $(project)_tb.vhd
entity = $(project)_tb

stop_time = 50us
time_resolution = 1ns

all:
	# 'analysis'
	ghdl -a $(FLAGS) TestbenchUtilsPkg.vhd convenc.vhd TestCtrl_e.vhd TbStream.vhd TbStream_SendGet1.vhd 

	#ghdl -a $(FLAGS) TestbenchUtilsPkg.vhd $(design) $(test)

	# 'elaborate'
	ghdl -e $(FLAGS) TbStream
	#ghdl -e $(FLAGS) $(entity)

	# 'run'
	ghdl -r $(FLAGS) TbStream --vcd=out.vcd --stop-time=$(stop_time)

linear: 

	# 'analysis'

	ghdl -a $(FLAGS) TestbenchUtilsPkg.vhd convenc.vhd convenc_tb.vhd

	# 'elaborate'
	ghdl -e $(FLAGS) convenc_tb

	# 'run'
	ghdl -r $(FLAGS) convenc_tb  --vcd=out.vcd --stop-time=$(stop_time)
view:
	gtkwave out.vcd
clean:
	rm *.cf $(entity).ghw
