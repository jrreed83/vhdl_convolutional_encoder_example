library ieee;
  use ieee.std_logic_1164.all;

entity convenc_top is
    generic 
    (
        NUM_INPUT_BITS  : natural := 8;
        NUM_OUTPUT_BITS : natural := 24
    );
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;

        -- input AXI-stream interface
        s_axis_data   : in  std_logic_vector(31 downto 0); 
        s_axis_valid  : in  std_logic;
        m_axis_ready  : out std_logic;
        s_axis_last   : in  std_logic;

        -- output AXI-stream interface
        m_axis_data:  out std_logic_vector(31 downto 0); 
        m_axis_valid: out std_logic;
        s_axis_ready: in  std_logic;
        m_axis_last:  out std_logic
    );
end entity;



architecture behavioral of convenc_top is  

    -- code necessary to convert individual signals to an interface.
    --ATTRIBUTE X_INTERFACE_INFO : STRING;
    --ATTRIBUTE X_INTERFACE_INFO of s_axis_data:  signal is "xilinx.com:interface:axis:1.0 S_AXIS TDATA";   
    --ATTRIBUTE X_INTERFACE_INFO of s_axis_valid: signal is "xilinx.com:interface:axis:1.0 S_AXIS TVALID";
    --ATTRIBUTE X_INTERFACE_INFO of m_axis_ready: signal is "xilinx.com:interface:axis:1.0 S_AXIS TREADY";    
    --ATTRIBUTE X_INTERFACE_INFO of s_axis_last:  signal is "xilinx.com:interface:axis:1.0 S_AXIS TLAST";    

    --ATTRIBUTE X_INTERFACE_INFO of m_axis_data:  signal is "xilinx.com:interface:axis:1.0 M_AXIS TDATA";   
    --ATTRIBUTE X_INTERFACE_INFO of m_axis_valid: signal is "xilinx.com:interface:axis:1.0 M_AXIS TVALID";
    --ATTRIBUTE X_INTERFACE_INFO of s_axis_ready: signal is "xilinx.com:interface:axis:1.0 M_AXIS TREADY";       
    --ATTRIBUTE X_INTERFACE_INFO of m_axis_last:  signal is "xilinx.com:interface:axis:1.0 M_AXIS TLAST";    

    component convenc is
        generic (
            NUM_INPUT_BITS  : natural;
            NUM_OUTPUT_BITS : natural
        );
        port (
            clk           : in  std_logic;
            rst           : in  std_logic;

            -- input AXI-stream interface
            s_axis_data   : in  std_logic_vector(NUM_INPUT_BITS-1 downto 0); -- in  unsigned(7 downto 0);
            s_axis_valid  : in  std_logic;
            m_axis_ready  : out std_logic;
            s_axis_last   : in  std_logic;
            -- output AXI-stream interface
            m_axis_data   : out std_logic_vector(NUM_OUTPUT_BITS-1 downto 0); --out unsigned(23 downto 0);
            m_axis_valid  : out std_logic;
            s_axis_ready  : in  std_logic;
            m_axis_last   : out std_logic
        );
    end component;

begin

    device : convenc 
        generic map (
            NUM_INPUT_BITS  => NUM_INPUT_BITS,
            NUM_OUTPUT_BITS => NUM_OUTPUT_BITS
        )
        port map (
            clk => clk,
            rst => rst,

            s_axis_data  => s_axis_data(NUM_INPUT_BITS-1 downto 0), 
            s_axis_valid => s_axis_valid, 
            m_axis_ready => m_axis_ready,
            s_axis_last  => s_axis_last,

            -- output AXI-stream interface
            m_axis_data  => m_axis_data(NUM_OUTPUT_BITS-1 downto 0),
            m_axis_valid => m_axis_valid,
            s_axis_ready => s_axis_ready,
            m_axis_last  => m_axis_last 
        );
end architecture;
