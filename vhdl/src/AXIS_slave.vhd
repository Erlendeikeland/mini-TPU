library ieee;
use ieee.std_logic_1164.all;

entity AXIS_slave is
    generic (
        DATA_WIDTH : integer := 32
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        
        tdata : in std_logic_vector((DATA_WIDTH - 1) downto 0);
        tlast : in std_logic;
        tready : out std_logic;
        tvalid : in std_logic
    );
end entity AXIS_slave;

architecture behave of AXIS_slave is

begin

    

end architecture;