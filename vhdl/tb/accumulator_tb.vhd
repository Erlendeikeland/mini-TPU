library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.minitpu_pkg.all;

entity accumulator_tb is
end entity accumulator_tb;

architecture behave of accumulator_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';

    constant WIDTH : natural := 4;
    constant DEPTH : natural := 8;

    signal data_in : output_array := (others => (others => '0'));
    signal data_out : output_array := (others => (others => '0'));

    type matrix_t is array (0 to ((SIZE * 2) - 2), 0 to (SIZE - 1)) of natural;
    constant data_matrix : matrix_t := (
        (1, 0, 0, 0),
        (5, 2, 0, 0),
        (9, 6, 3, 0),
        (13, 10, 7, 4),
        (0, 14, 11, 8),
        (0, 0, 15, 12),
        (0, 0, 0, 16)
    );

    type result_matrix_t is array (0 to (SIZE - 1), 0 to (SIZE - 1)) of natural;
    constant result_matrix : result_matrix_t := (
        (1, 2, 3, 4),
        (5, 6, 7, 8),
        (9, 10, 11, 12),
        (13, 14, 15, 16)
    );

begin

    accumulator_inst: entity work.accumulator
        generic map(
            WIDTH => WIDTH,
            DEPTH => DEPTH
        )
        port map(
            clk => clk,
            data_in => data_in,
            data_out => data_out
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        wait for CLK_PERIOD * 20;
        
        -- Write to accumulator
        for i in 0 to ((WIDTH * 2) - 2) loop
            for j in 0 to (WIDTH - 1) loop
                data_in(j) <= std_logic_vector(to_unsigned(data_matrix(i, j), MAX_ACCUM_WIDTH));
            end loop;
            wait for CLK_PERIOD;
        end loop;
            
        wait for CLK_PERIOD * 5;

        stop;
    end process;

end architecture;