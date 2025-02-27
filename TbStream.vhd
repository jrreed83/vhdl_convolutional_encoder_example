library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm; 
  context osvvm.OsvvmContext;

-- The model independent transaction stuff
library osvvm_common;
    context osvvm_common.OsvvmCommonContext;    

library osvvm_axi4;
    context osvvm_axi4.AxiStreamContext;

entity TbStream is 
end entity;


architecture TestHarness of TbStream is

    
    signal clk    : std_logic;
    signal rst    : std_logic;
    signal nReset : std_logic;

    constant Clock_Period : time := 10 ns;
    constant tpd          : time := 2 ns;


    constant AXI_TX_DATA_WIDTH   : integer := 24 ;
    constant AXI_TX_BYTE_WIDTH   : integer := AXI_TX_DATA_WIDTH/8 ; 
    
    constant AXI_RX_DATA_WIDTH   : integer := 8 ;
    constant AXI_RX_BYTE_WIDTH   : integer := AXI_RX_DATA_WIDTH/8 ; 
    
    --constant AXI_DATA_WIDTH   : integer := 32 ;
    --constant AXI_BYTE_WIDTH   : integer := AXI_DATA_WIDTH/8 ; 
    constant TID_MAX_WIDTH    : integer := 8 ;
    constant TDEST_MAX_WIDTH  : integer := 4 ;
    constant TUSER_MAX_WIDTH  : integer := 4 ;

    constant INIT_ID     : std_logic_vector(TID_MAX_WIDTH-1 downto 0)   := (others => '0') ; 
    constant INIT_DEST   : std_logic_vector(TDEST_MAX_WIDTH-1 downto 0) := (others => '0') ; 
    constant INIT_USER   : std_logic_vector(TUSER_MAX_WIDTH-1 downto 0) := (others => '0') ; 



    signal TxTValid, RxTValid    : std_logic ;
    signal TxTReady, RxTReady    : std_logic ; 
    signal TxTID   , RxTID       : std_logic_vector(TID_MAX_WIDTH-1 downto 0) ; 
    signal TxTDest , RxTDest     : std_logic_vector(TDEST_MAX_WIDTH-1 downto 0) ; 
    signal TxTUser , RxTUser     : std_logic_vector(TUSER_MAX_WIDTH-1 downto 0) ; 
    --signal TxTData , RxTData     : std_logic_vector(AXI_DATA_WIDTH-1 downto 0) ; 
    --signal TxTStrb , RxTStrb     : std_logic_vector(AXI_BYTE_WIDTH-1 downto 0) ; 
    --signal TxTKeep , RxTKeep     : std_logic_vector(AXI_BYTE_WIDTH-1 downto 0) ; 
    signal TxTLast , RxTLast     : std_logic ; 


    signal TxTStrb : std_logic_vector(AXI_TX_BYTE_WIDTH-1 downto 0) ; 
    signal RxTStrb : std_logic_vector(AXI_RX_BYTE_WIDTH-1 downto 0) ; 
    signal TxTKeep : std_logic_vector(AXI_TX_BYTE_WIDTH-1 downto 0) ; 
    signal RxTKeep : std_logic_vector(AXI_RX_BYTE_WIDTH-1 downto 0) ; 
    signal TxTData : std_logic_vector(AXI_TX_DATA_WIDTH-1 downto 0);
    signal RxTData : std_logic_vector(AXI_RX_DATA_WIDTH-1 downto 0);

    constant AXI_PARAM_WIDTH : integer := TID_MAX_WIDTH + TDEST_MAX_WIDTH + TUSER_MAX_WIDTH + 1 ;


    signal StreamTxRec, StreamRxRec : StreamRecType(

        DataToModel   (AXI_RX_DATA_WIDTH-1 downto 0),
        DataFromModel (AXI_TX_DATA_WIDTH-1 downto 0),
        ParamToModel  (AXI_PARAM_WIDTH-1   downto 0),
        ParamFromModel(AXI_PARAM_WIDTH-1   downto 0)
        --DataToModel   (AXI_DATA_WIDTH-1    downto 0),
        --DataFromModel (AXI_DATA_WIDTH-1    downto 0),
        --ParamToModel  (AXI_PARAM_WIDTH-1   downto 0),
        --ParamFromModel(AXI_PARAM_WIDTH-1   downto 0)
    ) ;  


    component TestCtrl is
        generic ( 
            ID_LEN       : integer ;
            DEST_LEN     : integer ;
            USER_LEN     : integer 
        ) ;
        port (
            -- Global Signal Interface
            nReset          : In    std_logic ;

            -- Transaction Interfaces
            StreamTxRec     : inout StreamRecType ;
            StreamRxRec     : inout StreamRecType 
        ) ;

  end component TestCtrl ;
begin

    ----------------------------------------------
    -- Device under test
    ----------------------------------------------
    DUT : entity work.convenc port map (
        clk          => clk,
        rst          => rst,

        -- Receive from AXIS transmitter
        s_axis_data  => RxTData, --(7 downto 0), -- The DUT expects 8 input bits, extract subsequence
        s_axis_valid => RxTValid,
        m_axis_ready => RxTReady,
  
        -- Send to AXIS receiver
        m_axis_data  => TxTData, --(23 downto 0), -- The dut outputs 24 bits, place in the larger std logic array 
        m_axis_valid => TxTValid,
        s_axis_ready => TxTReady
    );

    
    -----------------------------------------------
    -- Clock Generation
    -----------------------------------------------
    Osvvm.ClockResetPkg.CreateClock( 
        Clk    => clk,
        Period => Clock_Period
    );

    ----------------------------------------------
    -- Reset
    ----------------------------------------------
    Osvvm.ClockResetPkg.CreateReset ( 
        Reset       => rst,
        ResetActive => '1',
        Clk         => Clk,
        Period      => 7 * Clock_Period,
        tpd         => tpd
    ) ;

    nReset <= not rst;
    ----------------------------------------------
    -- AXIS-transmitter: Transaction -> AXIS
    ----------------------------------------------
    Transmitter: AxiStreamTransmitter
        generic map (
            INIT_ID        => INIT_ID  , 
            INIT_DEST      => INIT_DEST, 
            INIT_USER      => INIT_USER, 
            INIT_LAST      => 0,

            tperiod_Clk    => Clock_Period,

            tpd_Clk_TValid => tpd, 
            tpd_Clk_TID    => tpd, 
            tpd_Clk_TDest  => tpd, 
            tpd_Clk_TUser  => tpd, 
            tpd_Clk_TData  => tpd, 
            tpd_Clk_TStrb  => tpd, 
            tpd_Clk_TKeep  => tpd, 
            tpd_Clk_TLast  => tpd     
        )
        port map (
            Clk    => clk,
            nReset => nReset,

            -- Transaction interface: receive transactions from the test sequencer
            TransRec => StreamTxRec,

            -- wiggle the pins based on the transactions

            -- connect DUT's input pins
            TValid => RxTValid,
            TReady => RxTReady,
            TID    => RxTID,
            TDest  => RxTDest,
            TUser  => RxTUser,
            TData  => RxTData,
            TStrb  => RxTStrb,
            TKeep  => RxTKeep,
            TLast  => RxTLast

        );
    ----------------------------------------------
    -- AXIS-receiver: AXIS -> transaction
    ----------------------------------------------
    Receiver_1 : AxiStreamReceiver
        generic map (
            tperiod_Clk    => Clock_Period,
            INIT_ID        => INIT_ID  , 
            INIT_DEST      => INIT_DEST, 
            INIT_USER      => INIT_USER, 
            INIT_LAST      => 0,

            tpd_Clk_TReady => tpd  
        ) 
        port map (
            -- Globals
            Clk       => clk,
            nReset    => nReset,
      
            -- AXI Stream Interface
            -- connect DUT's output pins
            TValid    => TxTValid,
            TReady    => TxTReady,
            TID       => TxTID   ,
            TDest     => TxTDest ,
            TUser     => TxTUser ,
            TData     => TxTData ,
            TStrb     => TxTStrb ,
            TKeep     => TxTKeep ,
            TLast     => TxTLast ,

            -- Send transactions out
            TransRec  => StreamRxRec
        ) ;    

        
    ----------------------------------------------
    -- Transaction Sequencer
    ----------------------------------------------
    TestCtrl_1 : TestCtrl
        generic map (
            ID_LEN       => TxTID'length,
            DEST_LEN     => TxTDest'length,
            USER_LEN     => TxTUser'length
        )
        port map (
            -- Globals
            nReset       => nReset,

            -- Testbench Transaction Interfaces
            StreamTxRec  => StreamTxRec,
            StreamRxRec  => StreamRxRec
        ) ;
end architecture;
