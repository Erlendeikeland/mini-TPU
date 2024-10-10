library ieee;
use ieee.std_logic_1164.all;

entity AXIS_master is
    generic (
        DATA_WIDTH : integer := 32
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        
        tdata : out std_logic_vector((DATA_WIDTH - 1) downto 0);
        tlast : out std_logic;
        tready : in std_logic;
        tvalid : out std_logic
    );
end entity AXIS_master;

architecture behave of AXIS_master is

begin

    

end architecture;