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
        write_enable <= '1';
        for i in 0 to (WIDTH - 1) loop
            write_address <= i;
            for j in 0 to (WIDTH - 1) loop
                write_data(j) <= std_logic_vector(to_unsigned(i + 1, MAX_ACCUM_WIDTH));
            end loop;
            wait for CLK_PERIOD;
        end loop;
        write_enable <= '0';
            
        wait for CLK_PERIOD * 5;
        
        -- Read from accumulator and test the result
        for i in 0 to (WIDTH - 1) loop
            read_address <= i;
            wait for CLK_PERIOD * 2;
            for j in 0 to (WIDTH - 1) loop
                assert read_data(j) = std_logic_vector(to_unsigned(i + 1, MAX_ACCUM_WIDTH)) report "Mismatch at read_data(" & integer'image(j) & ")" severity error;
            end loop;
        end loop;
            
        wait for CLK_PERIOD * 5;

        -- Write to accumulator with accumulating
        write_enable <= '1';
        accumulate <= '1';
        for i in 0 to (WIDTH - 1) loop
            write_address <= i;
            for j in 0 to (WIDTH - 1) loop
                write_data(j) <= std_logic_vector(to_unsigned(i + 1, MAX_ACCUM_WIDTH));
            end loop;
            wait for CLK_PERIOD;
        end loop;
        write_enable <= '0';
        accumulate <= '0';

        wait for CLK_PERIOD * 5;

        -- Read from accumulator and test the result
        for i in 0 to (WIDTH - 1) loop
            read_address <= i;
            wait for CLK_PERIOD * 2;
            for j in 0 to (WIDTH - 1) loop
                assert read_data(j) = std_logic_vector(to_unsigned((i + 1) + (i + 1), MAX_ACCUM_WIDTH)) report "Mismatch at read_data(" & integer'image(j) & ")" severity error;
            end loop;
        end loop;
        
        stop;
    end process;

end architecture;