library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.minitpu_pkg.all;

entity weight_control_tb is
end entity weight_control_tb;

architecture behave of weight_control_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';
    signal reset : std_logic := '0';

    signal op_address : natural := 0;
    signal op_enable : std_logic := '0';
    signal busy : std_logic := '0';
    signal weight_buffer_enable : std_logic := '0';
    signal weight_buffer_read_address : natural := 0;
    signal systolic_array_weight_enable : std_logic := '0';
    signal systolic_array_weight_address : natural := 0;

begin

    weight_control_inst: entity work.weight_control
        port map(
            clk => clk,
            reset => reset,
            op_address => op_address,
            op_enable => op_enable,
            busy => busy,
            weight_buffer_enable => weight_buffer_enable,
            weight_buffer_read_address => weight_buffer_read_address,
            systolic_array_weight_enable => systolic_array_weight_enable,
            systolic_array_weight_address => systolic_array_weight_address
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
        op_address <= 2;
        wait for CLK_PERIOD;
        op_address <= 3;
        
        wait for CLK_PERIOD * 60;
        stop;
    end process;

end architecture;