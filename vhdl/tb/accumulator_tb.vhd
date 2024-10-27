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

    signal accumulate : std_logic := '0';
    signal write_address : natural := 0;
    signal write_enable : std_logic := '0';
    signal write_data : output_array := (others => (others => '0'));
    signal read_address : natural := 0;
    signal read_data : output_array := (others => (others => '0'));

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

begin

    accumulator_inst: entity work.accumulator
        generic map(
            WIDTH => WIDTH,
            DEPTH => DEPTH
        )
        port map(
            clk => clk,
            accumulate => accumulate,
            write_address => write_address,
            write_enable => write_enable,
            write_data => write_data,
            read_address => read_address,
            read_data => read_data
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        wait for CLK_PERIOD * 5;
        
        -- Write to accumulator without accumulating
        for i in 0 to ((WIDTH * 2) - 2) loop
            if i < WIDTH then
                write_enable <= '1';
                write_address <= i;
            else
                write_enable <= '0';
                write_address <= 0;
            end if;
            for j in 0 to (WIDTH - 1) loop
                write_data(j) <= std_logic_vector(to_unsigned(data_matrix(i, j), MAX_ACCUM_WIDTH));
            end loop;
            wait for CLK_PERIOD;
        end loop;
            
        wait for CLK_PERIOD * 5;
        
        -- Read from accumulator
        for i in 0 to ((WIDTH * 2) - 2) loop
            read_address <= i;
            wait for CLK_PERIOD;
        end loop;

        stop;
    end process;

end architecture;