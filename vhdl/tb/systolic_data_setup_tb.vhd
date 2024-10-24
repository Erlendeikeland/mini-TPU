library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.minitpu_pkg.all;

entity systolic_data_setup_tb is
end entity systolic_data_setup_tb;

architecture behave of systolic_data_setup_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';

    constant MATRIX_WIDTH : natural := 4;

    type test_array_2D is array (0 to (MATRIX_WIDTH - 1), 0 to (MATRIX_WIDTH - 1)) of natural;
    signal test_data : test_array_2D := (
        (0, 1, 2, 3),
        (4, 5, 6, 7),
        (8, 9, 10, 11),
        (12, 13, 14, 15)
    );

    signal data_in : data_array := (others => (others => '0'));
    signal data_out : data_array;

begin

    systolic_data_setup_inst: entity work.systolic_data_setup
        generic map(
            MATRIX_WIDTH => MATRIX_WIDTH
        )
        port map(
            clk => clk,
            data_in => data_in,
            data_out => data_out
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        wait for CLK_PERIOD * 5;
        
        for i in 0 to (MATRIX_WIDTH - 1) loop
            for j in 0 to (MATRIX_WIDTH - 1) loop
                data_in(j) <= std_logic_vector(to_unsigned(test_data(i, j), DATA_WIDTH));
            end loop;
            wait for CLK_PERIOD;
        end loop;

        wait for CLK_PERIOD * 5;

        stop;
    end process;

end architecture;