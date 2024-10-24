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

    constant MATRIX_WIDTH : natural := 4;

begin



    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        wait for CLK_PERIOD * 5;
        
        

        wait for CLK_PERIOD * 5;

        stop;
    end process;

end architecture;