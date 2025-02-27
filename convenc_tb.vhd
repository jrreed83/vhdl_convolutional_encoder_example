library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm; 
  context osvvm.OsvvmContext;
  -- Scoreboard stuff not included ...
  use osvvm.ScoreBoardPkg_Unsigned.all; 

library work;
  use work.TestbenchUtilsPkg.all;

-- The model independent transaction stuff
library osvvm_common;
    context osvvm_common.OsvvmCommonContext;    


entity convenc_tb is 
end entity;


architecture test of convenc_tb is

    signal clk: std_logic;
    signal rst: std_logic;
    
    -- To DUT
    signal m_axis_valid : std_logic;
    signal s_axis_ready : std_logic;
    signal m_axis_data  : std_logic_vector(7 downto 0) := (others => '0'); --unsigned(7 downto 0) := (others => '0');

    -- From DUT
    signal s_axis_valid : std_logic;
    signal m_axis_ready : std_logic;
    signal s_axis_data  : std_logic_vector(23 downto 0); --unsigned(23 downto 0);
   
    -- From DUT to scoreboard
    signal dut_out : std_logic_vector(23 downto 0) := (others => '0'); -- unsigned(23 downto 0) := (others => '0');

    component convenc is 
        port (
            clk           : in  std_logic;
            rst           : in  std_logic;
            s_axis_data   : in  std_logic_vector(7 downto 0); --unsigned(7 downto 0);
            s_axis_valid  : in  std_logic;
            m_axis_ready  : out std_logic;

            m_axis_data   : out std_logic_vector(23 downto 0); --unsigned(23 downto 0);
            m_axis_valid  : out std_logic;
            s_axis_ready  : in  std_logic
        );
    end component;


    signal test_done: integer_barrier;

    signal MyScoreboard : osvvm.ScoreboardPkg_Unsigned.ScoreboardIdType;

    signal TestRec: MyRecType;
begin


    Control_Process: process 
        variable count : integer := 0;
        variable item: unsigned(7 downto 0);
    begin 
        
        SetTestName("TbUart_Scoreboard1") ;
        MyScoreboard <= osvvm.ScoreboardPkg_Unsigned.NewID("FEC");

        wait for 0 ns; wait for 0 ns;
        
        osvvm.TranscriptPkg.TranscriptOpen("TEST.txt");
        
        -- Wait for test bench to complete 
        osvvm.TbUtilPkg.WaitForBarrier(test_done);

        -- Let's see what's in the score-board FIFO 
        report "Inspect Scoreboard";
        report " ---------------------------------";
        for i in 1 to GetItemCount(MyScoreboard) loop 
            item := Pop(MyScoreboard);
            report "Item # " & to_string(i) & " is " & to_hex_string(item);
        end loop;
        
        osvvm.TranscriptPkg.Print("this is a test");
        osvvm.TranscriptPkg.Print("another test");
        osvvm.TranscriptPkg.TranscriptClose;

        std.env.stop;
        wait;
    end process;
    


    dut : convenc port map (
        clk          => clk,
        rst          => rst,
        s_axis_data  => m_axis_data,
        s_axis_valid => m_axis_valid,
        m_axis_ready => s_axis_ready,
  
        m_axis_data  => s_axis_data,
        m_axis_valid => s_axis_valid,
        s_axis_ready => m_axis_ready
    );

    Osvvm.ClockResetPkg.CreateClock( 
        Clk    => clk,
        Period => 10 ns
    );

    reset: process begin 
        rst <= '0';
        wait for 10 ns;
        wait until rising_edge(clk);
        rst <= '1';
        wait for 100 ns;
        rst <= '0';
        wait;
    end process;

    
    ---------------------------------------------------------------------
    --
    -- AXIS Transmitter - send data to the DUT
    --
    ---------------------------------------------------------------------
    --AXI_Transmitter (
    --);
    -- want to receive transactions from the test sequencer and wiggle the pins 

    m_axis_valid <= '1';
    AXI_Transmitter_Proc: process 
        variable count : natural := 0;
        variable RV: osvvm.RandomPkg.RandomPType;
        variable data : std_logic_vector(7 downto 0);
    begin
        wait until falling_edge(rst);

        while count < 10 loop
            wait until rising_edge(clk);
            if m_axis_valid = '1' and s_axis_ready = '1' then 
                data :=  std_logic_vector(RV.RandUnsigned(Min=>0, Max=>255, Size=>data'length));
                
                osvvm.ScoreboardPkg_Unsigned.Push(MyScoreboard, unsigned(data));
                m_axis_data <= data;
                count := count + 1;

            end if;
        end loop;
        
        osvvm.TbUtilPkg.WaitForBarrier(test_done);
    
    end process;




    --------------------------------------------------------------------------
    --
    -- AXIS Receiver - receive data from the DUT
    --
    --------------------------------------------------------------------------
    m_axis_ready <= '1';
    process 
        variable count : natural := 0;
    begin 
        wait until rising_edge(clk);
        if m_axis_ready = '1' and s_axis_valid = '1' then 
            dut_out <= s_axis_data;

            -- It appears that the dut is 3 transactions behind the model.  Maybe add a register?
            if dut_out /= "00000000" then 
                report "dut   : " & " " & to_string(count) & " " & to_hex_string(dut_out);
            end if;
            report "model : " & " " & to_string(count) & " " & to_hex_string(fec_model(unsigned(m_axis_data)));

            count := count + 1;
        end if;
    end process;

    ---------------------------------------------------------------------------
    --
    -- Score Board
    --
    ---------------------------------------------------------------------------
    --score_board: process begin 
    --    
    --end process;

end architecture;
