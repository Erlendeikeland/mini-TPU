library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.minitpu_pkg.all;

entity accumulator_control_tb is
end entity accumulator_control_tb;

architecture behave of accumulator_control_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';
    signal reset : std_logic := '0';

    signal op_accumulator_address : natural := 0;
    signal op_enable : std_logic := '0';
    signal busy : std_logic := '0';
    signal accumulator_accumulate : std_logic := '0';
    signal accumulator_write_address : natural := 0;
    signal accumulator_write_enable : std_logic := '0';

begin
    
    accumulator_control_inst: entity work.accumulator_control
        port map(
            clk => clk,
            reset => reset,
            op_accumulator_address => op_accumulator_address,
            op_enable => op_enable,
            busy => busy,
            accumulator_accumulate => accumulator_accumulate,
            accumulator_write_address => accumulator_write_address,
            accumulator_write_enable => accumulator_write_enable
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        wait for CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;
        reset <= '1';
        wait;
    end process;

    process
    begin
        wait for CLK_PERIOD * 5;

        op_enable <= '1';
        op_accumulator_address <= 2;
        wait for CLK_PERIOD;
        op_enable <= '0';

        wait for CLK_PERIOD * 10;

        op_enable <= '1';
        op_accumulator_address <= 6;
        wait for CLK_PERIOD;
        op_accumulator_address <= 0;
        
        wait for CLK_PERIOD * 60;
        stop;
    end process;

end architecture;