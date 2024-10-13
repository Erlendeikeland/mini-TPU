library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.minitpu_pkg.all;

entity systolicarray_tb is
end entity systolicarray_tb;

architecture behave of systolicarray_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '0';

    signal enable : std_logic := '0';
    signal data_in : data_vector_t(0 to (SIZE - 1)) := (others => (others => '0'));
    signal data_out : output_vector_t(0 to (SIZE - 1)) := (others => (others => '0'));
    signal weight : weight_vector_t(0 to (SIZE - 1)) := (others => (others => '0'));
    signal load_weight : std_logic := '0';

    constant MAX_DATA : natural := (2 ** DATA_WIDTH) - 1;
    constant MAX_WEIGHT : natural := (2 ** WEIGHT_WIDTH) - 1;

    type data_matrix_t is array (0 to (SIZE - 1), 0 to (SIZE - 1)) of natural range 0 to MAX_DATA;
    signal data_matrix : data_matrix_t := (
        (1, 2, 3),
        (4, 5, 6),
        (7, 8, 9)
    );

begin

    systolicarray_inst: entity work.systolicarray
        port map(
            clk => clk,
            enable => enable,
            data_in => data_in,
            data_out => data_out,
            weight => weight,
            load_weight => load_weight
        );

    process
    begin
        clk <= '1';
        wait for CLK_PERIOD/2;
        clk <= '0';
        wait for CLK_PERIOD/2;
    end process;

    process
    begin
        wait for CLK_PERIOD * 2;

        weight <= (others => std_logic_vector(to_unsigned(3, WEIGHT_WIDTH)));
        load_weight <= '1';
        wait for CLK_PERIOD;
        load_weight <= '0';

        wait for CLK_PERIOD * 2;

        enable <= '1';

        for i in 0 to (SIZE * 2 + 1) loop
            for j in 0 to (SIZE - 1) loop
                if i - j >= 0 and i - j < SIZE then
                    data_in(j) <= std_logic_vector(to_unsigned(data_matrix(j, i - j), DATA_WIDTH));
                else
                    data_in(j) <= (others => '0');
                end if;
            end loop;
            wait for CLK_PERIOD;
        end loop;

        enable <= '0';

        wait;
    end process;

end architecture;