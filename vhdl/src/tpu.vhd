library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity tpu is
    port (
        clk : in std_logic;

        weight_buffer_port_0_enable : in std_logic;
        weight_buffer_port_0_write_data : in weight_array;
        weight_buffer_port_0_write_address : in natural;
        weight_buffer_port_0_write_enable : in std_logic;
        weight_buffer_port_1_enable : in std_logic;
        weight_buffer_port_1_read_address : in natural;

        unified_buffer_master_enable : in std_logic;
        unified_buffer_master_write_address : in natural;
        unified_buffer_master_write_enable : in std_logic;
        unified_buffer_master_write_data : in data_array;
        unified_buffer_master_read_address : in natural;
        unified_buffer_master_read_data : out data_array;
        unified_buffer_port_0_enable : in std_logic;
        unified_buffer_port_0_write_address : in natural;
        unified_buffer_port_0_write_enable : in std_logic;
        unified_buffer_port_1_enable : in std_logic;
        unified_buffer_port_1_read_address : in natural;

        systolic_array_weight_address : in natural;
        systolic_array_weight_enable : in std_logic;

        accumulator_accumulate : in std_logic;
        accumulator_write_address : in natural;
        accumulator_write_enable : in std_logic;
        accumulator_read_address : in natural
    );
end entity tpu;

architecture behave of tpu is

    signal weight_buffer_port_1_read_data : weight_array;

    signal unified_buffer_port_1_read_data : data_array;

    signal systolic_array_data_setup_data_out : data_array;

    signal systolic_array_data_out : output_array;

    signal accumulator_read_data : output_array;

    signal activation_data_out : data_array;

begin

    weight_buffer_inst: entity work.weight_buffer
        generic map(
            WIDTH => 4,
            DEPTH => 8
        )
        port map(
            clk => clk,
            port_0_enable => weight_buffer_port_0_enable,
            port_0_write_data => weight_buffer_port_0_write_data,
            port_0_write_address => weight_buffer_port_0_write_address,
            port_0_write_enable => weight_buffer_port_0_write_enable,
            port_1_enable => weight_buffer_port_1_enable,
            port_1_read_data => weight_buffer_port_1_read_data, --
            port_1_read_address => weight_buffer_port_1_read_address
        );

    unified_buffer_inst: entity work.unified_buffer
        generic map(
            WIDTH => 4,
            DEPTH => 8
        )
        port map(
            clk => clk,
            master_enable => unified_buffer_master_enable,
            master_write_address => unified_buffer_master_write_address,
            master_write_enable => unified_buffer_master_write_enable,
            master_write_data => unified_buffer_master_write_data,
            master_read_address => unified_buffer_master_read_address,
            master_read_data => unified_buffer_master_read_data,
            port_0_enable => unified_buffer_port_0_enable,
            port_0_write_address => unified_buffer_port_0_write_address,
            port_0_write_enable => unified_buffer_port_0_write_enable,
            port_0_write_data => activation_data_out, --
            port_1_enable => unified_buffer_port_1_enable,
            port_1_read_address => unified_buffer_port_1_read_address,
            port_1_read_data => unified_buffer_port_1_read_data --
        );

    systolic_data_setup_inst: entity work.systolic_data_setup
        generic map(
            MATRIX_WIDTH => 4
        )
        port map(
            clk => clk,
            data_in => unified_buffer_port_1_read_data, --
            data_out => systolic_array_data_setup_data_out --
        );

    systolic_array_inst: entity work.systolic_array
        port map(
            clk => clk,
            enable => '1',
            data_in => systolic_array_data_setup_data_out, --
            data_out => systolic_array_data_out, --
            weight_in => weight_buffer_port_1_read_data, --
            weight_address => systolic_array_weight_address,
            weight_enable => systolic_array_weight_enable
        );

    accumulator_inst: entity work.accumulator
        generic map(
            WIDTH => 4,
            DEPTH => 8
        )
        port map(
            clk => clk,
            accumulate => accumulator_accumulate,
            write_address => accumulator_write_address,
            write_enable => accumulator_write_enable,
            write_data => systolic_array_data_out, --
            read_address => accumulator_read_address,
            read_data => accumulator_read_data --
        );

    activation_inst: entity work.activation
        generic map(
            WIDTH => 4
        )
        port map(
            clk => clk,
            data_in => accumulator_read_data, --
            data_out => activation_data_out --
        );

end architecture;