library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity accumulator is
    generic (
        WIDTH : natural;
        DEPTH : natural
    );
    port (
        clk : in std_logic;

        accumulate : in std_logic;

        -- Write port
        write_address : in natural range 0 to (DEPTH - 1);
        write_enable : in std_logic;
        write_data : in output_array;

        -- Read port
        read_address : in natural range 0 to (DEPTH - 1);
        read_data : out output_array
    );
end entity accumulator;

architecture behave of accumulator is

    type RAM_t is array(0 to (DEPTH - 1)) of std_logic_vector((MAX_ACCUM_WIDTH * WIDTH) - 1 downto 0);
    shared variable RAM : RAM_t;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if write_enable = '1' then
                if accumulate = '1' then
                    for i in 0 to (WIDTH - 1) loop
                        RAM(write_address)(i * MAX_ACCUM_WIDTH + (MAX_ACCUM_WIDTH - 1) downto i * MAX_ACCUM_WIDTH) := std_logic_vector(unsigned(RAM(write_address)(i * MAX_ACCUM_WIDTH + (MAX_ACCUM_WIDTH - 1) downto i * MAX_ACCUM_WIDTH)) + unsigned(write_data(i)));
                    end loop;
                else
                    for i in 0 to (WIDTH - 1) loop
                        RAM(write_address)(i * MAX_ACCUM_WIDTH + (MAX_ACCUM_WIDTH - 1) downto i * MAX_ACCUM_WIDTH) := write_data(i);
                        report_line("Write data: " & to_hstring(write_data(i)));
                    end loop;
                    report_line("");
                end if;
            end if;

            for i in 0 to (WIDTH - 1) loop
                read_data(i) <= RAM(read_address)(i * MAX_ACCUM_WIDTH + (MAX_ACCUM_WIDTH - 1) downto i * MAX_ACCUM_WIDTH);
            end loop;
        end if;
    end process;

end architecture;