-- Buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity weight_buffer is
    generic (
        WIDTH : integer;
        DEPTH : integer
    );
    port (
        clk : in std_logic;
        
        -- Port 0 (Write)
        port_0_enable : in std_logic;
        port_0_write_data : in weight_array;
        port_0_write_address : in natural range 0 to (DEPTH - 1);
        port_0_write_enable : in std_logic;

        -- Port 1 (Read)
        port_1_enable : in std_logic;
        port_1_read_data : out weight_array;
        port_1_read_address : in natural range 0 to (DEPTH - 1)
    );
end entity weight_buffer;

architecture behave of weight_buffer is

    type RAM_t is array(0 to (DEPTH - 1)) of std_logic_vector((DATA_WIDTH * WIDTH) - 1 downto 0);
    shared variable RAM : RAM_t;

begin

    -- Port 0 (Write)
        process (clk)
    begin
        if rising_edge(clk) then
            if port_0_enable = '1' then
                if port_0_write_enable = '1' then
                    for i in 0 to (WIDTH - 1) loop
                        ram(port_0_write_address)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH) := port_0_write_data(i);
                    end loop;
                end if;            
            end if;
        end if;
    end process;
    
    -- Port 1 (Read)
    process (clk)
    begin
        if rising_edge(clk) then
            if port_1_enable = '1' then
                for i in 0 to (WIDTH - 1) loop
                    port_1_read_data(i) <= ram(port_1_read_address)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH);
                end loop;    
            end if;
        end if;
    end process;

end architecture;