library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package utils_pkg is 

    function fec_model(x: unsigned(7 downto 0)) return unsigned; 
end;

package body utils_pkg is 
    
    -- want to put this in a seperate package
    function fec_model(x : unsigned(7 downto 0)) return unsigned is 
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
end;

