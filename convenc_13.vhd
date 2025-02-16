library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity convenc_13 is 
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;

        -- input AXI-stream interface
        s_axis_data   : in  unsigned(7 downto 0);
        s_axis_valid  : in  std_logic;
        m_axis_ready  : out std_logic;

        -- output AXI-stream interface
        m_axis_data:  out unsigned(23 downto 0);
        m_axis_valid: out std_logic;
        s_axis_ready: in  std_logic
    );
end entity;



architecture v1 of convenc_13 is 

    signal reg_in  : unsigned(2 downto 0)  := (others => '0');
    signal reg_out : unsigned(2 downto 0)  := (others => '0');
    signal addr_in : unsigned(5 downto 0)  := (others => '0');

    signal addr_out : unsigned(7 downto 0) := (others => '0');
 
    signal pkt_in :  unsigned( 9 downto 0) := (others => '0'); -- two extra bits to flush through
    signal pkt_out:  unsigned(29 downto 0) := (others => '0');
    
    type State is (idle, start, encoding, done);


    signal curr_state: State := idle;
    signal next_state: State := idle;

    signal read_done:  std_logic;
    signal write_done: std_logic;

    signal encoding_complete: std_logic;


    signal output: unsigned(23 downto 0) := (others => '0');

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
                    next_state <= done;
                else 
                    next_state <= curr_state;
                end if;
            when done =>
                if write_done then 
                    next_state <= idle;
                else 
                    next_state <= curr_state;
                end if;
        end case;

    end process;     
    

    encoding_process: process(clk) begin 
        if rising_edge(clk) then 

            if rst = '1' then 
                reg_in  <= (others => '0');
                reg_out <= (others => '0');
            else
                if curr_state = done then
                    addr_in  <= (others => '0');
                    addr_out <= (others => '0');
                    reg_in   <= (others => '0');
                    reg_out  <= (others => '0');
                    output   <= pkt_out(29 downto 6);
                    report "output = " & to_string(output);
                elsif curr_state = encoding then
                    -- state LOAD_AND_CALCULATE
                    -- LOAD
                    reg_in(0) <= pkt_in(to_integer(addr_in));
                    reg_in(1) <= reg_in(0);
                    reg_in(2) <= reg_in(1);
                    

                    -- one cycle behind LOAD
                    reg_out(0) <= reg_in(0) xor reg_in(1) xor reg_in(2);
                    reg_out(1) <=               reg_in(1) xor reg_in(2);
                    reg_out(2) <= reg_in(0)               xor reg_in(2);

                    -- two cycles behind LOAD
                    pkt_out(to_integer(addr_out)+0) <= reg_out(0);
                    pkt_out(to_integer(addr_out)+1) <= reg_out(1);
                    pkt_out(to_integer(addr_out)+2) <= reg_out(2);
                    
                end if;


                if next_state = encoding then
                    addr_in  <= addr_in  + 1;
                    addr_out <= addr_out + 3;
                end if;
            end if;
        end if;
    end process;


    -- Encoding is complete when once we've processed every bit in the data word.
    encoding_complete <= '1' when addr_in = pkt_in'length-1 else '0'; 

    -- Not satisfied with this system, when encoding is complete, the next state gets set but because 
    -- the process above looks for the current state, the address increments one more time.  We don'time
    -- want to grab aother bit from the input after we've exhausted it.
    
    -------------------------------
    --
    -- AXIS handshake for the input
    --
    -------------------------------
    m_axis_ready <= '1' when curr_state = idle else '0';

    
    axis_handshake: process(clk) begin 
        if rising_edge(clk) then 
            read_done <= '0';
            if m_axis_ready = '1' and s_axis_valid = '1' then 
                --
                -- Because of the pipeline in the "encoding" state, the output has a latency of 2.
                -- As a result, need to run the encoding stage two clock cycles more that we would
                -- otherwise.  A simple way to do this it to simply embed the input 8 bits into a 
                -- larger 10 bit-wide word and go through the encoding process until the 10
                -- bits have been processed.
                --
                pkt_in <= "00" & s_axis_data;

                read_done <= '1';
            end if;
        end if;
    end process;


    --------------------------------
    --
    -- AXIS handshake for the output
    --
    --------------------------------
    m_axis_valid <= '1' when curr_state = done else '0'; 


end architecture;
