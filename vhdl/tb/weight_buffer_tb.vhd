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

    constant WIDTH : natural := 8;
    constant DEPTH : natural := 8;

    constant PIPELINE_STAGES : natural := 1;

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
            DEPTH => DEPTH,
            PIPELINE_STAGES => PIPELINE_STAGES
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
        variable write_data : weight_array;
    begin
        wait for CLK_PERIOD * 5;
        
        -- Write port 0
        port_0_enable <= '1';
        port_0_write_enable <= '1';
        port_0_write_address <= 0;
        for i in 0 to (WIDTH - 1) loop
            write_data(i) := std_logic_vector(to_unsigned(i, DATA_WIDTH));
        end loop;
        port_0_write_data <= write_data;
        wait for CLK_PERIOD;
        port_0_enable <= '0';
        port_0_write_enable <= '0';

        wait for CLK_PERIOD * 5;

        -- Read port 1
        port_1_enable <= '1';
        port_1_read_address <= 0;
        wait for CLK_PERIOD;
        port_1_enable <= '0';

        wait for CLK_PERIOD * 5;

        stop;
    end process;

end architecture;