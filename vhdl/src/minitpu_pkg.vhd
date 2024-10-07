library ieee;
use ieee.std_logic_1164.all;

package minitpu_pkg is

    constant WIDTH : integer := 4;

    constant INTEGER_WIDTH : integer := 8;
    
    type matrix_signal is array(0 to (WIDTH - 1), 0 to (WIDTH - 1)) of std_logic_vector((INTEGER_WIDTH - 1) downto 0);

    type vector_signal is array(0 to (WIDTH - 1)) of std_logic_vector((INTEGER_WIDTH - 1) downto 0);        

end package;

package body minitpu_pkg is
    
end package body;