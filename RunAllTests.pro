

library osvvm_FEC

LinkLibraryDirectory $::OsvvmLibraries 

SetSaveWaves true 

analyze  convenc.vhd
analyze  convenc_top.vhd
analyze  TestbenchUtilsPkg.vhd 
analyze  TestCtrl_e.vhd 
analyze  TbFEC.vhd 
analyze  TbFEC_Scoreboard1.vhd 

TestName TbFEC_Scoreboard1
simulate TbFEC_Scoreboard1

