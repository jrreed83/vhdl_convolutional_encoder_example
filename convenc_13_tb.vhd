library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library osvvm;
  use osvvm.ClockResetPkg.all;


entity convenc_13_tb is 
end entity;


architecture test of convenc_13_tb is

    signal clk: std_logic;
    signal rst: std_logic;
    

    signal m_axis_valid : std_logic;
    signal s_axis_ready : std_logic;
    signal m_axis_data  : unsigned(7 downto 0);


    signal s_axis_valid : std_logic;
    signal m_axis_ready : std_logic;
    signal s_axis_data  : unsigned(23 downto 0);
    
    component convenc_13 is 
        port (
            clk           : in  std_logic;
            rst           : in  std_logic;
            s_axis_data   : in  unsigned(7 downto 0);
            s_axis_valid  : in  std_logic;
            m_axis_ready  : out std_logic;

            m_axis_data   : out unsigned(23 downto 0);
            m_axis_valid  : out std_logic;
            s_axis_ready  : in  std_logic
        );
    end component;
begin

    dut : convenc_13 port map (
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


    m_axis_valid <= '1';
    process begin 
        wait until rising_edge(clk);
        if m_axis_valid = '1' and s_axis_ready = '1' then 
            m_axis_data <= 8x"ac";
        end if;
    end process;
end architecture;
