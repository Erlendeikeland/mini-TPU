-- Buffer

library ieee;
use ieee.std_logic_1164.all;

entity buffer is
    generic (
        WIDTH : integer := 8;
        DEPTH : integer := 32;
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        
        -- Write port
        wdata : in std_logic_vector((WIDTH - 1) downto 0);
        waddr : in std_logic_vector((DEPTH - 1) downto 0);
        wen : in std_logic;

        -- Read port
        rdata : out std_logic_vector((WIDTH - 1) downto 0);
        raddr : in std_logic_vector((DEPTH - 1) downto 0);
        ren : in std_logic
    );
end entity buffer;

architecture behave of buffer is

    type RAM_t is array(0 to (DEPTH - 1)) of std_logic_vector((WIDTH - 1) downto 0);

begin

    

end architecture;