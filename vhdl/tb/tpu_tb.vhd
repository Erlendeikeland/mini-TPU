library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.minitpu_pkg.all;

entity tpu_tb is
end entity tpu_tb;

architecture behave of tpu_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';
    signal reset : std_logic := '0';

    signal fifo_write_enable : std_logic := '0';
    signal fifo_write_data : op_t;

    signal weight_buffer_port_0_enable : std_logic := '0';
    signal weight_buffer_port_0_write_data : weight_array := (others => (others => '0'));
    signal weight_buffer_port_0_write_address : natural := 0;
    signal weight_buffer_port_0_write_enable : std_logic := '0';

    signal unified_buffer_master_enable : std_logic := '0';
    signal unified_buffer_master_write_address : natural := 0;
    signal unified_buffer_master_write_enable : std_logic := '0';
    signal unified_buffer_master_write_data : data_array := (others => (others => '0'));
    signal unified_buffer_master_read_address : natural := 0;
    signal unified_buffer_master_read_data : data_array := (others => (others => '0'));

begin

    tpu_inst: entity work.tpu
        port map(
            clk => clk,
            reset => reset,
            fifo_write_enable => fifo_write_enable,
            fifo_write_data => fifo_write_data,
            weight_buffer_port_0_enable => weight_buffer_port_0_enable,
            weight_buffer_port_0_write_data => weight_buffer_port_0_write_data,
            weight_buffer_port_0_write_address => weight_buffer_port_0_write_address,
            weight_buffer_port_0_write_enable => weight_buffer_port_0_write_enable,
            unified_buffer_master_enable => unified_buffer_master_enable,
            unified_buffer_master_write_address => unified_buffer_master_write_address,
            unified_buffer_master_write_enable => unified_buffer_master_write_enable,
            unified_buffer_master_write_data => unified_buffer_master_write_data,
            unified_buffer_master_read_address => unified_buffer_master_read_address,
            unified_buffer_master_read_data => unified_buffer_master_read_data
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

        -- Write data to weight buffer
        weight_buffer_port_0_enable <= '1';
        weight_buffer_port_0_write_enable <= '1';
        for i in 0 to (SIZE - 1) loop
            weight_buffer_port_0_write_address <= i + 2;
            for j in 0 to (SIZE - 1) loop
                weight_buffer_port_0_write_data(j) <= std_logic_vector(to_unsigned(i + j, DATA_WIDTH));
            end loop;
            wait for CLK_PERIOD;
        end loop;
        weight_buffer_port_0_enable <= '0';
        weight_buffer_port_0_write_enable <= '1';
        
        wait for CLK_PERIOD * 5;

        -- Write data to unified buffer
        unified_buffer_master_enable <= '1';
        unified_buffer_master_write_enable <= '1';
        for i in 0 to (SIZE - 1) loop
            unified_buffer_master_write_address <= i;
            for j in 0 to (SIZE - 1) loop
                unified_buffer_master_write_data(j) <= std_logic_vector(to_unsigned(i + j, DATA_WIDTH));
            end loop;
            wait for CLK_PERIOD;
        end loop;
        unified_buffer_master_enable <= '0';
        unified_buffer_master_write_enable <= '0';

        wait for CLK_PERIOD * 5;

        -- Write instructions to FIFO
        fifo_write_enable <= '1';
        fifo_write_data.op_code <= LOAD_WEIGHTS;
        fifo_write_data.unified_buffer_address <= 0;
        fifo_write_data.weight_buffer_address <= 2;
        fifo_write_data.accumulator_address <= 0;
        wait for CLK_PERIOD;
        fifo_write_enable <= '0';

        wait for CLK_PERIOD * 10;

        fifo_write_enable <= '1';
        fifo_write_data.op_code <= MATRIX_MULTIPLY;
        fifo_write_data.unified_buffer_address <= 0;
        fifo_write_data.weight_buffer_address <= 0;
        fifo_write_data.accumulator_address <= 4;
        wait for CLK_PERIOD;
        fifo_write_enable <= '0';

        wait for CLK_PERIOD * 60;

        -- Read data from unified buffer
        unified_buffer_master_enable <= '1';
        for i in 0 to (SIZE - 1) loop
            unified_buffer_master_read_address <= i + 4;
            wait for CLK_PERIOD * 2;
            report_line(integer'image(to_integer(unsigned(unified_buffer_master_read_data(0)))) & " " & integer'image(to_integer(unsigned(unified_buffer_master_read_data(1)))) & " " & integer'image(to_integer(unsigned(unified_buffer_master_read_data(2)))) & " " & integer'image(to_integer(unsigned(unified_buffer_master_read_data(3)))));
        end loop;
        unified_buffer_master_enable <= '0';

        wait for CLK_PERIOD * 5; 

        stop;
    end process;

end architecture;