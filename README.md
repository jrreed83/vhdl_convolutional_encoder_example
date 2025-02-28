## Convolutional Encoder Design and Testbench

- Rate 1/3 convolutional encoder.
- Uses OSVVM scoreboard, AXI-stream verification components, and constrained randomization.

## Scripting

My default TCL shell is the one that came with the Anaconda distribution of Python.  When I try to run OSVVM through
this version, nothing works.  So I need to run the other version I have on my system.

1. rlwrap /usr/bin/tclsh 
2. source ../OsvvmLibraries/Scripts/StartUp.tcl 
3. build RunAllTests.pro 

To get this to work, you need to link to the libraries.  Here's a link on the OSVVM official stire 
that spells out how to do that: https://osvvm.org/archives/2280.
