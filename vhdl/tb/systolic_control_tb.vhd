library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.minitpu_pkg.all;

entity systolic_control_tb is
end entity systolic_control_tb;

architecture behave of systolic_control_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';
    signal reset : std_logic := '0';

    signal op_unified_buffer_address : natural := 0;
    signal op_accumulator_address : natural := 0;
    signal op_enable : std_logic := '0';
    signal busy : std_logic := '0';
    signal unified_buffer_enable : std_logic := '0';
    signal unified_buffer_read_address : natural := 0;

begin
    
    systolic_control_inst: entity work.systolic_control
        port map(
            clk => clk,
            reset => reset,
            op_unified_buffer_address => op_unified_buffer_address,
            op_enable => op_enable,
            busy => busy,
            unified_buffer_enable => unified_buffer_enable,
            unified_buffer_read_address => unified_buffer_read_address
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
        op_unified_buffer_address <= 2;
        wait for CLK_PERIOD;
        op_enable <= '0';
        
        wait for CLK_PERIOD * 60;
        stop;
    end process;

end architecture;