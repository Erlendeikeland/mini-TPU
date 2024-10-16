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
        reset : in std_logic;
        
        -- Write port
        write_data : in weight_array;
        write_addr : in std_logic_vector((DEPTH - 1) downto 0);
        write_en : in std_logic;

        -- Read port
        read_data : out weight_array;
        read_addr : in std_logic_vector((DEPTH - 1) downto 0);
        read_en : in std_logic
    );
end entity weight_buffer;

architecture behave of weight_buffer is

    type RAM_t is array(0 to (DEPTH - 1)) of std_logic_vector((WEIGHT_WIDTH * WIDTH) - 1 downto 0);
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
                        ram(to_integer(unsigned(write_addr)))(i * WEIGHT_WIDTH + (WEIGHT_WIDTH - 1) downto i * WEIGHT_WIDTH) <= write_data(i);
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
                    read_data(i) <= ram(to_integer(unsigned(read_addr)))(i * WEIGHT_WIDTH + (WEIGHT_WIDTH - 1) downto i * WEIGHT_WIDTH);
                end loop;
            end if;
        end if;
    end process;

end architecture;