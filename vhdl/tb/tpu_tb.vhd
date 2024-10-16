library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.minitpu_pkg.all;

entity tpu_tb is
end entity tpu_tb;

architecture behave of tpu_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '0';
    signal reset : std_logic := '0';

begin

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        reset <= '1';
        wait for CLK_PERIOD;
        reset <= '0';
        wait;
    end process;

    process
    begin
        wait for CLK_PERIOD * 5;


        wait for CLK_PERIOD * 5;

        stop;
    end process;

end architecture;