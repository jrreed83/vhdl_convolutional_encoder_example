architecture Scoreboard1 of TestCtrl is

    signal   TestDone : integer_barrier := 1 ;
   
    constant num_words: natural := 50;

    use work.TestbenchUtilsPkg.all;

    -- use scoreboard ...
    use osvvm.ScoreboardPkg_slv.all ;
    
    signal MyScoreboard : osvvm.ScoreboardPkg_slv.ScoreboardIdType;
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbFEC_Scoreboard1"); 
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable INFO logs

    MyScoreboard <= NewID("SB1");

    -- Wait for simulation elaboration/initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 35 ms) ;
    AlertIf(now >= 35 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ;   
   
       
    -- Expecting two check errors at 128 and 256
    EndOfTestReports; --(ExternalErrors => (0, -2, 0)) ; 
    std.env.stop ;
    wait ; 
  end process ControlProc ; 

  
  ------------------------------------------------------------
  -- AxiTransmitterProc
  --   Generate transactions for AxiTransmitter
  ------------------------------------------------------------
  TransmitterProc : process
    
    variable Data : std_logic_vector(DATA_WIDTH_TX-1 downto 0) := (others=>'0');
    
    variable OffSet : integer ; 
    variable TransactionCount : integer; 
    variable ErrorCount : integer; 
    variable CurTime : time ; 
    variable TxAlertLogID : AlertLogIDType ;
    variable Rand: RandomPType;
  begin
    wait until nReset = '1' ;  
    WaitForClock(StreamTxRec, 2) ; 
    
    log("Send " & to_string(num_words) & " words with each byte incrementing") ;
    for i in 1 to num_words loop 
        -- Create words one byte at a time  
        Data := Rand.RandSlv(Min=>0, Max=> 2**DATA_WIDTH_TX-1, Size=>DATA_WIDTH_TX);
        Send(StreamTxRec, Data) ;

        Push(MyScoreboard, fec_model(Data));         
        
        GetTransactionCount(StreamTxRec, TransactionCount) ;
        wait for 0 ns ;       wait for 0 ns ; 
    end loop ;
   
    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(StreamTxRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process TransmitterProc ;


  ------------------------------------------------------------
  -- AxiReceiverProc
  --   Generate transactions for AxiReceiver
  ------------------------------------------------------------
  ReceiverProc : process
      
    variable RxData : std_logic_vector(DATA_WIDTH_RX-1 downto 0) ;  
     
    variable OffSet : integer ; 
    variable TransactionCount : integer ;     
    variable ErrorCount : integer; 
    variable CurTime : time ; 
    variable TxAlertLogID : AlertLogIDType ; 
  begin
    WaitForClock(StreamRxRec, 2) ; 

    -- The convolutional encoder is one transaction behind.  
    -- So let's get the first one and throw it away.
    Get(StreamRxRec, RxData);

    for i in 1 to num_words-1 loop 
        
        Get(StreamRxRec, RxData) ; 
        Check(MyScoreboard, RxData);
        
        wait for 0 ns; 
     end loop ;
     
    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(StreamRxRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process ReceiverProc ;

end architecture ;

Configuration TbFEC_SendGet1 of TbFEC is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(Scoreboard1) ; 
    end for ; 
  end for ; 
end Configuration ; 
