library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;
  use ieee.numeric_std_unsigned.all ;
  
library osvvm ; 
  context osvvm.OsvvmContext ; 

library osvvm_AXI4 ;
    context osvvm_AXI4.AxiStreamContext ;


--use work.OsvvmTestCommonPkg.all ;

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
  --constant DATA_WIDTH : integer := StreamTxRec.DataToModel'length ; 
  --constant DATA_BYTES : integer := DATA_WIDTH/8 ; 
  
  constant DATA_WIDTH_TX : integer := StreamTxRec.DataToModel'length ; 
  constant DATA_BYTES_TX : integer := DATA_WIDTH_TX/8 ; 

  constant DATA_WIDTH_RX : integer := StreamRxRec.DataFromModel'length ; 
  constant DATA_BYTES_RX : integer := DATA_WIDTH_RX/8 ; 
  --constant DATA_WIDTH : integer := StreamTxRec.DataToModel'length ; 
  --constant DATA_BYTES : integer := DATA_WIDTH/8 ; 
end entity TestCtrl ;
