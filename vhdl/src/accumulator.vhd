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

        write_address : in natural range 0 to (DEPTH - 1);
        write_enable : in std_logic;
        write_data : in output_array;

        read_address : in natural range 0 to (DEPTH - 1);
        read_data : out output_array
    );
end entity accumulator;

architecture behave of accumulator is

    type RAM_t is array(0 to (DEPTH - 1)) of std_logic_vector((MAX_ACCUM_WIDTH * WIDTH) - 1 downto 0);
    shared variable RAM : RAM_t;

    type shift_address_t is array(0 to (WIDTH - 1)) of natural range 0 to (DEPTH - 1);
    type shift_data_t is array(0 to (WIDTH - 1)) of output_array;

    signal read_data_reg : output_array;

begin

    process (clk)

        variable shift_address : shift_address_t;
        variable shift_data : shift_data_t;
        variable shift_write_enable : std_logic_vector(0 to (WIDTH - 1));
        variable shift_accumulate : std_logic_vector(0 to (WIDTH - 1));

    begin
        if rising_edge(clk) then
            shift_address := write_address & shift_address(0 to (WIDTH - 2));
            shift_write_enable := write_enable & shift_write_enable(0 to (WIDTH - 2));
            shift_data := write_data & shift_data(0 to (WIDTH - 2));
            shift_accumulate := accumulate & shift_accumulate(0 to (WIDTH - 2));

            if shift_write_enable(SIZE - 1) = '1' then
                if shift_accumulate(SIZE - 1) = '1' then
                    for i in 0 to (WIDTH - 1) loop
                        RAM(shift_address(SIZE - 1))(i * MAX_ACCUM_WIDTH + (MAX_ACCUM_WIDTH - 1) downto i * MAX_ACCUM_WIDTH) := std_logic_vector(unsigned(RAM(shift_address(SIZE - 1))(i * MAX_ACCUM_WIDTH + (MAX_ACCUM_WIDTH - 1) downto i * MAX_ACCUM_WIDTH)) + unsigned(shift_data((SIZE - 1) - i)(0 + i)));
                    end loop;
                else
                    for i in 0 to (WIDTH - 1) loop
                        RAM(shift_address(SIZE - 1))(i * MAX_ACCUM_WIDTH + (MAX_ACCUM_WIDTH - 1) downto i * MAX_ACCUM_WIDTH) := shift_data((SIZE - 1) - i)(0 + i);
                    end loop;
                end if;
            end if;

            for i in 0 to (WIDTH - 1) loop
                read_data_reg(i) <= RAM(read_address)(i * MAX_ACCUM_WIDTH + (MAX_ACCUM_WIDTH - 1) downto i * MAX_ACCUM_WIDTH);
            end loop;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            read_data <= read_data_reg;
        end if;
    end process;

end architecture;