library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.minitpu_pkg.all;

entity weight_buffer_tb is
end entity weight_buffer_tb;

architecture behave of weight_buffer_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';

    signal reset : std_logic := '0';

    constant WIDTH : natural := 8;
    constant DEPTH : natural := 8;

    signal port_0_enable : std_logic := '0';
    signal port_0_write_address : natural := 0;
    signal port_0_write_enable : std_logic := '0';
    signal port_0_write_data : weight_array := (others => (others => '0'));

    signal port_1_enable : std_logic := '0';
    signal port_1_read_address : natural := 0;
    signal port_1_read_data : weight_array := (others => (others => '0'));

begin

    weight_buffer_inst: entity work.weight_buffer
        generic map(
            WIDTH => WIDTH,
            DEPTH => DEPTH
        )
        port map(
            clk => clk,
            port_0_enable => port_0_enable,
            port_0_write_data => port_0_write_data,
            port_0_write_address => port_0_write_address,
            port_0_write_enable => port_0_write_enable,
            port_1_enable => port_1_enable,
            port_1_read_data => port_1_read_data,
            port_1_read_address => port_1_read_address
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
        variable write_data : weight_array;
    begin
        wait for CLK_PERIOD * 5;
        
        -- Write port 0
        port_0_enable <= '1';
        port_0_write_enable <= '1';
        for i in 0 to (DEPTH - 1) loop
            port_0_write_address <= i;
            for j in 0 to (WIDTH - 1) loop
                write_data(j) := std_logic_vector(to_unsigned(i * WIDTH + j, DATA_WIDTH));
            end loop;
            port_0_write_data <= write_data;
            wait for CLK_PERIOD;
        end loop;
        port_0_enable <= '0';
        port_0_write_enable <= '0';

        wait for CLK_PERIOD * 5;

        -- Read port 1
        port_1_enable <= '1';
        for i in 0 to (DEPTH - 1) loop
            port_1_read_address <= i;
            wait for CLK_PERIOD * 2;
            for j in 0 to (WIDTH - 1) loop
                assert port_1_read_data(j) = std_logic_vector(to_unsigned(i * WIDTH + j, DATA_WIDTH)) report "Error at address " & integer'image(i) & " and data " & integer'image(j) severity failure;
            end loop;
        end loop;
        port_1_enable <= '0';

        wait for CLK_PERIOD * 5;

        stop;
    end process;

end architecture;