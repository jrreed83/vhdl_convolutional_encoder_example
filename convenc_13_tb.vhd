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
    
    signal encoded_data : unsigned(23 downto 0);

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



    function convenc_model(x : unsigned(7 downto 0)) return unsigned is 
        variable output: unsigned(23 downto 0) := (others => '0');
        variable reg   : unsigned( 2 downto 0) := (others => '0');
        variable j     : natural := 0;
    begin 

        for i in 0 to x'length-1 loop 
            reg(2) := reg(1);
            reg(1) := reg(0);
            reg(0) := x(i);

            output(j+0) := reg(0) xor reg(1) xor reg(2);
            output(j+1) :=            reg(1) xor reg(2);
            output(j+2) := reg(0)            xor reg(2);

            j := j + 3;
        end loop;
        return output;
    end function;

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

    ------------------------------------------------
    --
    -- AXIS Transmitter - send data to the DUT
    --
    ------------------------------------------------
    m_axis_valid <= '1';
    process 
        variable count : natural := 0;
    begin
        wait until falling_edge(rst);
        -- Need to clean this up.  Want the valid signal to be 1 clock cycle wide.  
        -- The encoder should just be waiting ...
        while count < 10 loop
            --wait for 300 ns;
            --wait until rising_edge(clk);
            --m_axis_valid <= '1';
            wait until rising_edge(clk);
            if m_axis_valid = '1' and s_axis_ready = '1' then 
                m_axis_data <= "10100101";
                
                count := count + 1;
            end if;
            --m_axis_valid <= '0';
        end loop;
        std.env.finish;
    end process;




    ------------------------------------------------
    --
    -- AXIS Receiver - receive data from the DUT
    --
    ------------------------------------------------
    m_axis_ready <= '1';
    process begin 
        wait until rising_edge(clk);
        if m_axis_ready = '1' and s_axis_valid = '1' then 
            encoded_data <= s_axis_data;
            report "RESULT :" & to_string(encoded_data);
            report "hdddec :" & to_string(convenc_model("10100101"));
        end if;
    end process;

    -----------------------------------------------
    --
    -- Score Board
    --
    -----------------------------------------------
    --score_board: process begin 
    --    wait until transaction_done'transaction;

    --end process;

end architecture;
