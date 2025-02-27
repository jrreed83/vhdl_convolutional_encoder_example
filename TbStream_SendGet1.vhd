architecture SendGet1 of TestCtrl is

    signal   TestDone : integer_barrier := 1 ;
   
    constant num_words: natural := 5;


    use work.TestbenchUtilsPkg.all;
begin

  ------------------------------------------------------------
  -- ControlProc
  --   Set up AlertLog and wait for end of test
  ------------------------------------------------------------
  ControlProc : process
  begin
    -- Initialization of test
    SetTestName("TbStream_SendGet1") ;
    SetLogEnable(PASSED, TRUE) ;    -- Enable PASSED logs
    SetLogEnable(INFO, TRUE) ;    -- Enable INFO logs

    -- Wait for simulation elaboration/initialization 
    wait for 0 ns ;  wait for 0 ns ;
    TranscriptOpen ;
    SetTranscriptMirror(TRUE) ; 

    -- Wait for Design Reset
    wait until nReset = '1' ;  
    ClearAlerts ;

    -- Wait for test to finish
    WaitForBarrier(TestDone, 35 ms) ;
    AlertIf(now >= 35 ms, "Test finished due to timeout") ;
    AlertIf(GetAffirmCount < 1, "Test is not Self-Checking");
    
    TranscriptClose ; 
    --AffirmIfTranscriptsMatch(OSVVM_VALIDATED_RESULTS_DIR) ;   
   
       
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
    variable Data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others=>'0');
    variable OffSet : integer ; 
    variable TransactionCount : integer; 
    variable ErrorCount : integer; 
    variable CurTime : time ; 
    variable TxAlertLogID : AlertLogIDType ; 
  begin
    wait until nReset = '1' ;  
    WaitForClock(StreamTxRec, 2) ; 
    
    log("Send " & to_string(num_words) & " words with each byte incrementing") ;
    for i in 1 to num_words loop 
        -- Create words one byte at a time
        Data(7 downto 0) := std_logic_vector(to_unsigned(i, 8));  
        Send(StreamTxRec, Data) ;
        
        -- want to push to score board too 
        
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
    variable PreviousModel: std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');  
    variable CurrentModel:  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');  
    variable RxData : std_logic_vector(DATA_WIDTH-1 downto 0) ;  
    variable OffSet : integer ; 
    variable TransactionCount : integer ;     
    variable ErrorCount : integer; 
    variable CurTime : time ; 
    variable TxAlertLogID : AlertLogIDType ; 
  begin
    WaitForClock(StreamRxRec, 2) ; 
    
    for i in 1 to num_words loop 
        
        PreviousModel := CurrentModel;
        CurrentModel(23 downto 0) := fec_model(std_logic_vector(to_unsigned(i, 8)));  
        
        Get(StreamRxRec, RxData) ; 

        AffirmIfEqual(RxData(23 downto 0), PreviousModel(23 downto 0), "Get: ");
        wait for 0 ns; 
     end loop ;
     
    -- Wait for outputs to propagate and signal TestDone
    WaitForClock(StreamRxRec, 2) ;
    WaitForBarrier(TestDone) ;
    wait ;
  end process ReceiverProc ;

end SendGet1 ;

Configuration TbStream_SendGet1 of TbStream is
  for TestHarness
    for TestCtrl_1 : TestCtrl
      use entity work.TestCtrl(SendGet1) ; 
    end for ; 
  end for ; 
end TbStream_SendGet1 ; 
