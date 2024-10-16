-- Buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity data_buffer is
    generic (
        WIDTH : integer;
        DEPTH : integer
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        
        -- Write port
        write_data : in data_array;
        write_addr : in natural range 0 to (DEPTH - 1);
        write_en : in std_logic;

        -- Read port
        read_data : out data_array;
        read_addr : in natural range 0 to (DEPTH - 1);
        read_en : in std_logic
    );
end entity data_buffer;

architecture behave of data_buffer is

    type RAM_t is array(0 to (DEPTH - 1)) of std_logic_vector((DATA_WIDTH * WIDTH) - 1 downto 0);
    signal ram : RAM_t := (others => (others => '0'));

begin

    -- Write process
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                ram <= (others => (others => '0'));
            else
                if write_en = '1' then
                    for i in 0 to (WIDTH - 1) loop
                        ram(write_addr)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH) <= write_data(i);
                    end loop;
                end if;
            end if;
        end if;
    end process;

    -- Read process
    process (clk)
    begin
        if rising_edge(clk) then
            if read_en = '1' then
                for i in 0 to (WIDTH - 1) loop
                    read_data(i) <= ram(read_addr)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH);
                end loop;
            end if;
        end if;
    end process;

end architecture;