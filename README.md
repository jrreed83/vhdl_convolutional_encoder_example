## Convolutional Encoder Design and Testbench

- Rate 1/3 convolutional encoder.
- Uses OSVVM scoreboard, AXI-Stream verification components, and constrained randomization.

The testbench environment consists of the following elements:

* design under test
* sequencer
* test-harness 
* score board


## Scripting

My default TCL shell came with the Anaconda distribution of Python.  This version totally chokes on 
the OSVVM scripts.  Nothing works.  So I ran the other TCL shell I have on my system.  Here are the 
instructions to run my test bench:

1. Fire up the TCL shell 

```sh  
rlwrap /usr/bin/tclsh
``` 

2. Start the OSVVM scripting environment

```sh
source ../OsvvmLibraries/Scripts/StartUp.tcl 
```

3. Run the test(s) 

```sh
build RunAllTests.pro 
```

To get this to work, you need to link to the libraries.  Here's a link on the OSVVM official stire 
that spells out how to do that: https://osvvm.org/archives/2280.

By default,  the OSVVM script system will not dump signals to a file for a waveform viewer.  You can enable it by setting 
a flag in your TCL script.  The problem is that it only dumps .ghw files, which I can't get to load into GTKWAVE for whatever
reason.  To get around this, I manually edited the VendorScripts_GHDL.tcl file in the scripts subfolder so that a .vcd text file
gets generated.  This isn't a great solution either.  Besides having to hack someone elses code, .vcd files can get pretty large
and they don't understand vhdl enumerations.  

## Vivado

Vivado doesn't let you create a block for a Vivado block diagram from a VHDL-2008 entity.  You run into the same problem with SystemVerilog.  
My current workaround is to create a VHDL wrapper for the VHDL-2008 entity that doesn't need any of the fancy features VHDL-2008
offers.  Then everything works.  Pretty annoying! 

## Pynq 

To use the Pynq libraries from the Python command line, you need to login as root and use python3.  Once you'version
ssh'd into the development board, issue `sudo -i` at the command line and type in your password again.  Now you're the 
root user.

1. Login 

```sh
ssh xilinx@192.168.2.99 
```

2. Login as root 

```sh 
sudo -i 
```

3. Start up Python 

```sh 
python3
```

4. Load overlay 

```sh 
import numpy as np 
from pynq import Overlay 
from pynq import allocate 

ol = Overlay("fec_loopback/fec_loopback.bit")
dma = ol.axi_dma_0

i_buffer = allocate(shape=(1,), dtype=np.uint32)
o_buffer = allocate(shape=(1,), dtype=np.uint32)

i_buffer[0] = 3

dma.sendchannel.transfer(i_buffer)
dma.recvchannel.transfer(o_buffer)
dma.sendchannel.wait()
dma.recvchannel.wait()
```

## DMA

The memory-mapped address width should be set to 64 bits.  Otherwise the loopback test fails every other word.

