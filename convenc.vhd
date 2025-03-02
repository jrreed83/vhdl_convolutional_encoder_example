library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity convenc is
    generic (
        NUM_INPUT_BITS  : natural := 8;
        NUM_OUTPUT_BITS : natural := NUM_INPUT_BITS * 3
    );
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;

        -- input AXI-stream interface
        s_axis_data   : in  std_logic_vector(NUM_INPUT_BITS-1 downto 0); 
        s_axis_valid  : in  std_logic;
        m_axis_ready  : out std_logic;
        s_axis_last   : in  std_logic;

        -- output AXI-stream interface
        m_axis_data   : out std_logic_vector(NUM_OUTPUT_BITS-1 downto 0); 
        m_axis_valid  : out std_logic;
        s_axis_ready  : in  std_logic;
        m_axis_last   : out std_logic
    );
end entity;



architecture behavioral of convenc is  

    signal reg_in  : std_logic_vector(2 downto 0); --unsigned(2 downto 0)  := (others => '0');
    signal fec_out : std_logic_vector(2 downto 0); --unsigned(2 downto 0)  := (others => '0');
    signal addr_in : unsigned(5 downto 0)  := (others => '0');

    signal addr_out : unsigned(7 downto 0) := (others => '0');
 
    signal pkt_in :  std_logic_vector( 8 downto 0) := (others => '0'); --unsigned( 8 downto 0) := (others => '0'); -- two extra bits to flush through
    signal pkt_out:  std_logic_vector(26 downto 0) := (others => '0'); -- unsigned(26 downto 0) := (others => '0');

    ---------------------------------------------------------------------------------
    -- Problem :   issue with ghw file when using OSVVM, so I need to resort 
    --             to using VCD for waveform dumps.  However, VCD doesn't understand
    --             enumerations in VHDL.  As an alternative, I'm manually encoding
    --             the state-machine using one-hot encoding.
    ---------------------------------------------------------------------------------
    subtype State is std_logic_vector(4 downto 0);
    constant idle     : std_logic_vector(4 downto 0) := "00001";
    constant start    : std_logic_vector(4 downto 0) := "00010";
    constant encoding : std_logic_vector(4 downto 0) := "00100";
    constant truncate : std_logic_vector(4 downto 0) := "01000";
    constant done     : std_logic_vector(4 downto 0) := "10000";
    
    --type State is (idle, start, encoding, truncate, done);
    --attribute fsm_encoding: string;
    --attribute fsm_encoding of state: type is "one-hot";

    signal curr_state: State := idle;
    signal next_state: State := idle;

    signal read_done:  std_logic;
    signal write_done: std_logic;

    signal encoding_complete: std_logic;


    signal output:  std_logic_vector(23 downto 0) := (others => '0'); 
    
    signal num_tx_pkts : unsigned(3 downto 0) := (others => '0');
begin

    --------------------------------------------------------
    --
    -- State Machine 
    --
    --------------------------------------------------------
    process (clk) begin 
        if rising_edge(clk) then 
            if rst = '1' then 
                curr_state <= idle;
            else 
                curr_state <= next_state;
            end if;
        end if;
    end process;


    state_mapping: process (all) begin
        next_state <= curr_state;

        case (curr_state) is 
            when idle =>
                if read_done then 
                    next_state <= start;
                else 
                    next_state <= curr_state;
                end if;
            
            when start =>
                next_state <= encoding;

            when encoding =>
                if encoding_complete then 
                    next_state <= truncate;
                else 
                    next_state <= curr_state;
                end if;
            
            when truncate =>
                next_state <= done;
            
            when done =>
                if write_done then 
                    next_state <= idle;
                else 
                    next_state <= curr_state;
                end if;
            when others =>
                next_state <= curr_state;
        end case;

    end process;     
    
    
    encoding_process: process(clk) begin 
        if rising_edge(clk) then 

            if rst = '1' then 
                reg_in   <= (others => '0');
                addr_in  <= (others => '0');
                addr_out <= (others => '0');
            else
                if curr_state = done then
                    addr_in  <= (others => '0');
                    addr_out <= (others => '0');
                    reg_in   <= (others => '0');

                elsif curr_state = truncate then 
                    -- the lower bits are zeros
                    output <= pkt_out(26 downto 3);
                
                elsif curr_state = encoding then
                    reg_in(0) <= pkt_in(to_integer(addr_in));
                    reg_in(1) <= reg_in(0);
                    reg_in(2) <= reg_in(1);

                    -- The encoded outputs occur 1 clock cycle after the encoding step
                    pkt_out(to_integer(addr_out+0)) <= fec_out(0);
                    pkt_out(to_integer(addr_out+1)) <= fec_out(1);
                    pkt_out(to_integer(addr_out+2)) <= fec_out(2);
                        
                    addr_in  <= addr_in  + 1;
                    addr_out <= addr_out + 3;
                end if;


            end if;
        end if;
    end process;

    
    -- Encoding is complete when once we've processed every bit in the data word.
    encoding_complete <= '1' when addr_in = pkt_in'length-1 else '0'; 
    


    -----------------------------------------------------------------------------
    --
    -- Convolutional encoder output
    --
    -- Because the outputs are calculated in a combinational logic
    -- block, they appear roughly in-phase with the input register
    -- values.  Of course there is propagation delay to worry about,
    -- but these calculations are so simple that it should be negligible.
    --
    -------------------------------------------------------------------------------
    process(all) begin 
        fec_out <= (others => '0');
        if curr_state = encoding then
            fec_out(0) <= reg_in(0) xor reg_in(1) xor reg_in(2);
            fec_out(1) <=               reg_in(1) xor reg_in(2);
            fec_out(2) <= reg_in(0)               xor reg_in(2);
        end if;
    end process;

    -------------------------------------------------------------------------------------------
    --
    -- AXIS handshake for the input
    --
    -- This logic ensures that the valid and ready signals overlap high
    -- for exactly one clock cycle.  When these two signals are both high
    -- on a rising clock edge, the state transitions from 'idle' to 'encoding'
    -- by asserting an interal 'read_done' signal.
    --
    --
    --
    --
    -------------------------------------------------------------------------------------------
    
    m_axis_ready <= '1' when curr_state = idle else '0'; 
    read_done    <= m_axis_ready and s_axis_valid;
    axis_handshake_input: process(clk) begin 
        if rising_edge(clk) then 
            if rst = '1' then 
                pkt_in <= (others => '0');
            else 
                if m_axis_ready = '1' and s_axis_valid = '1' then 
                    pkt_in <= "0" & s_axis_data;
                end if;
            end if;
        end if;
    end process;


    ------------------------------------------------------------------------
    --
    -- AXIS handshake for the output
    --
    ------------------------------------------------------------------------
    m_axis_valid <= '1' when curr_state = done else '0'; 
    write_done   <= m_axis_valid  and s_axis_ready;
    
    axis_handshake_output: process(clk) begin 
        if rising_edge(clk) then
            if rst = '1' then
                m_axis_data <= (others => '0');
            else 
                if m_axis_valid = '1' and s_axis_ready = '1' then 
                    m_axis_data <= output;
                end if;
            end if; 
        end if;
    end process;

    ------------------------------------------------------------------------
    --
    -- Dealing with the AXI LAST Signal
    --
    ------------------------------------------------------------------------
    --process (clk) begin 
    --    if rising_edge(clk) then 
    --        if rst then 
    --            num_tx_pkts <= (others => '0');
    --        else 
    --            if write_done then
    --                if num_tx_pkts = 1 then 
    --                    num_tx_pkts <= (others => '0');
    --                else 
    --                    num_tx_pkts <= num_tx_pkts + 1;
    --                end if;
    --            end if;
    --        end if;
    --    end if;
    --end process;

    m_axis_last <= m_axis_valid; --'1' when (num_tx_pkts = 1 and m_axis_valid = '1') else '0';
end architecture;
