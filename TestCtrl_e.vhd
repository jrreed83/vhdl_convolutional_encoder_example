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
  constant DATA_WIDTH_TX : integer := StreamTxRec.DataToModel'length ; 
  constant DATA_BYTES_TX : integer := DATA_WIDTH_TX/8 ; 

  -- From the DUT to the AXIS receiver
  constant DATA_WIDTH_RX : integer := StreamRxRec.DataFromModel'length ; 
  constant DATA_BYTES_RX : integer := DATA_WIDTH_RX/8 ; 
end entity TestCtrl ;
