FLAGS = --std=08 -P../OsvvmLibraries/sim_ghdl/VHDL_LIBS/GHDL-5.0.0-dev
project=convenc
design = $(project).vhd 
test = $(project)_tb.vhd
entity = $(project)_tb

stop_time = 50us
time_resolution = 1ns

all:
	# 'analysis'
	ghdl -a $(FLAGS) $(test) $(design)
	# 'elaborate'
	ghdl -e $(FLAGS) $(entity) 
	# 'run'
	ghdl -r $(FLAGS) $(entity) --wave=$(entity).ghw --stop-time=$(stop_time)

view:
	gtkwave $(entity).ghw
clean:
	rm *.cf $(entity).ghw
