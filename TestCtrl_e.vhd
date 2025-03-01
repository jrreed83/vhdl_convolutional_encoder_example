library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;
  use ieee.numeric_std_unsigned.all ;
  
library osvvm ; 
  context osvvm.OsvvmContext ; 

library osvvm_AXI4 ;
    context osvvm_AXI4.AxiStreamContext ;


entity TestCtrl is
  generic ( 
    ID_LEN       : integer ;
    DEST_LEN     : integer ;
    USER_LEN     : integer 
  ) ;
  port (
      -- Global Signal Interface
      nReset             : In    std_logic ;

      -- Transaction Interfaces
      StreamTxRec        : InOut StreamRecType ;
      StreamRxRec        : InOut StreamRecType 

  ) ;

  -- Derive AXI interface properties from the StreamTxRec
  
  -- From the AXIS transmitter to the DUT
  constant DATA_WIDTH : integer := StreamTxRec.DataToModel'length ; 
  constant DATA_BYTES : integer := DATA_WIDTH/8 ; 

end entity TestCtrl ;
