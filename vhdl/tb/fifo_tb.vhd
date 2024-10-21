library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.env.stop;

use work.minitpu_pkg.all;

entity fifo_tb is
end entity fifo_tb;

architecture rtl of fifo_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';
    
    signal reset : std_logic := '0';

    constant DEPTH : natural := 16;
    signal write_data : op_t := (others => '0');
    signal write_en : std_logic := '0';
    signal full : std_logic;
    signal read_data : op_t := (others => '0');
    signal read_en : std_logic := '0';
    signal empty : std_logic;

begin

    fifo_inst: entity work.fifo
        generic map(
            DEPTH => DEPTH
        )
        port map(
            clk => clk,
            reset => reset,
            write_en => write_en,
            write_data => write_data,
            full => full,
            read_en => read_en,
            read_data => read_data,
            empty => empty
        );

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