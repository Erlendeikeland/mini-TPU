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

    signal weight_buffer_port_0_enable : std_logic := '0';
    signal weight_buffer_port_0_write_data : weight_array := (others => (others => '0'));
    signal weight_buffer_port_0_write_address : natural := 0;
    signal weight_buffer_port_0_write_enable : std_logic := '0';
    signal weight_buffer_port_1_enable : std_logic := '0';
    signal weight_buffer_port_1_read_address : natural := 0;

    signal unified_buffer_master_enable : std_logic := '0';
    signal unified_buffer_master_write_address : natural := 0;
    signal unified_buffer_master_write_enable : std_logic := '0';
    signal unified_buffer_master_write_data : data_array := (others => (others => '0'));
    signal unified_buffer_master_read_address : natural := 0;
    signal unified_buffer_master_read_data : data_array := (others => (others => '0'));
    signal unified_buffer_port_0_enable : std_logic := '0';
    signal unified_buffer_port_0_write_address : natural := 0;
    signal unified_buffer_port_0_write_enable : std_logic := '0';
    signal unified_buffer_port_1_enable : std_logic := '0';
    signal unified_buffer_port_1_read_address : natural := 0;

    signal systolic_array_weight_address : natural := 0;
    signal systolic_array_weight_enable : std_logic := '0';
    
    signal accumulator_accumulate : std_logic := '0';
    signal accumulator_write_address : natural := 0;
    signal accumulator_write_enable : std_logic := '0';
    signal accumulator_read_address : natural := 0;

begin

    tpu_inst: entity work.tpu
        port map(
            clk => clk,
            weight_buffer_port_0_enable => weight_buffer_port_0_enable,
            weight_buffer_port_0_write_data => weight_buffer_port_0_write_data,
            weight_buffer_port_0_write_address => weight_buffer_port_0_write_address,
            weight_buffer_port_0_write_enable => weight_buffer_port_0_write_enable,
            weight_buffer_port_1_enable => weight_buffer_port_1_enable,
            weight_buffer_port_1_read_address => weight_buffer_port_1_read_address,
            unified_buffer_master_enable => unified_buffer_master_enable,
            unified_buffer_master_write_address => unified_buffer_master_write_address,
            unified_buffer_master_write_enable => unified_buffer_master_write_enable,
            unified_buffer_master_write_data => unified_buffer_master_write_data,
            unified_buffer_master_read_address => unified_buffer_master_read_address,
            unified_buffer_master_read_data => unified_buffer_master_read_data,
            unified_buffer_port_0_enable => unified_buffer_port_0_enable,
            unified_buffer_port_0_write_address => unified_buffer_port_0_write_address,
            unified_buffer_port_0_write_enable => unified_buffer_port_0_write_enable,
            unified_buffer_port_1_enable => unified_buffer_port_1_enable,
            unified_buffer_port_1_read_address => unified_buffer_port_1_read_address,
            systolic_array_weight_address => systolic_array_weight_address,
            systolic_array_weight_enable => systolic_array_weight_enable,
            accumulator_accumulate => accumulator_accumulate,
            accumulator_write_address => accumulator_write_address,
            accumulator_write_enable => accumulator_write_enable,
            accumulator_read_address => accumulator_read_address
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

        -- Write data to weight buffer
        weight_buffer_port_0_enable <= '1';
        weight_buffer_port_0_write_enable <= '1';
        for i in 0 to (SIZE - 1) loop
            weight_buffer_port_0_write_address <= i;
            for j in 0 to (SIZE - 1) loop
                weight_buffer_port_0_write_data(j) <= std_logic_vector(to_unsigned(i + 1, WEIGHT_WIDTH));
            end loop;
            WAIT FOR CLK_PERIOD;
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
                unified_buffer_master_write_data(j) <= std_logic_vector(to_unsigned(i + 1, DATA_WIDTH));
            end loop;
            WAIT FOR CLK_PERIOD;
        end loop;
        unified_buffer_master_enable <= '0';
        unified_buffer_master_write_enable <= '0';

        wait for CLK_PERIOD * 5;

        -- Transfer weights from weight buffer to systolic array
        for i in 0 to (SIZE - 1) loop
            weight_buffer_port_1_read_address <= i;
            weight_buffer_port_1_enable <= '1';
            wait for CLK_PERIOD;
            weight_buffer_port_1_enable <= '0';
            systolic_array_weight_address <= i;
            systolic_array_weight_enable <= '1';
            wait for CLK_PERIOD;
            systolic_array_weight_enable <= '0';
        end loop;

        wait for CLK_PERIOD * 5;

        -- Read data from unified buffer into systolic array data setup
        unified_buffer_port_1_enable <= '1';
        for i in 0 to (SIZE - 1) loop
            unified_buffer_port_1_read_address <= i;
            wait for CLK_PERIOD;
        end loop;
        unified_buffer_port_1_enable <= '0';

        wait for CLK_PERIOD;

        -- Accumulate data
        accumulator_accumulate <= '0';
        accumulator_write_enable <= '1';
        for i in 0 to (SIZE - 1) loop
            accumulator_write_address <= i;
            wait for CLK_PERIOD;
        end loop;

        wait for CLK_PERIOD * 5;

        stop;
    end process;

end architecture;