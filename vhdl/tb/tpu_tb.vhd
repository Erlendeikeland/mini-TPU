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
    signal reset : std_logic := '1';

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

        procedure write_weight_buffer(
            constant address : in natural;
            constant value : in natural
        ) is
        begin
            weight_buffer_port_0_enable <= '1';
            weight_buffer_port_0_write_enable <= '1';
            for i in 0 to (SIZE - 1) loop
                weight_buffer_port_0_write_address <=  address + i;
                for j in 0 to (SIZE - 1) loop
                    weight_buffer_port_0_write_data(j) <= std_logic_vector(to_unsigned(value, DATA_WIDTH));
                end loop;
                wait for CLK_PERIOD;
            end loop;
            weight_buffer_port_0_enable <= '0';
            weight_buffer_port_0_write_enable <= '0';
        end procedure;

        procedure write_unified_buffer(
            constant address : in natural;
            constant value : in natural
        ) is
        begin
            unified_buffer_master_enable <= '1';
            unified_buffer_master_write_enable <= '1';
            for i in 0 to (SIZE - 1) loop
                unified_buffer_master_write_address <= address + i;
                for j in 0 to (SIZE - 1) loop
                    unified_buffer_master_write_data(j) <= std_logic_vector(to_unsigned(value, DATA_WIDTH));
                end loop;
                wait for CLK_PERIOD;
            end loop;
            unified_buffer_master_enable <= '0';
            unified_buffer_master_write_enable <= '0';
        end procedure;

    begin
        wait for CLK_PERIOD * 5;

        -- Write data to weight buffer
        write_weight_buffer(0, 2);
        write_weight_buffer(SIZE, 3);

        wait for CLK_PERIOD * 5;

        -- Write data to unified buffer
        write_unified_buffer(0, 1);
        write_unified_buffer(SIZE, 4);

        wait for CLK_PERIOD * 5;

        fifo_write_enable <= '1';
        fifo_write_data(1 downto 0) <= LOAD_WEIGHTS;
        fifo_write_data(31 downto 2) <= std_logic_vector(to_unsigned(0, 30));
        wait for CLK_PERIOD;
        fifo_write_enable <= '0';
        
        fifo_write_enable <= '1';
        fifo_write_data(1 downto 0) <= MATRIX_MULTIPLY;
        fifo_write_data(31 downto 17) <= std_logic_vector(to_unsigned(0, 15));
        fifo_write_data(16 downto 2) <= std_logic_vector(to_unsigned(SIZE * 2, 15));
        wait for CLK_PERIOD;
        fifo_write_enable <= '0';

        fifo_write_enable <= '1';
        fifo_write_data(1 downto 0) <= LOAD_WEIGHTS;
        fifo_write_data(31 downto 2) <= std_logic_vector(to_unsigned(SIZE, 30));
        wait for CLK_PERIOD;
        fifo_write_enable <= '0';

        fifo_write_enable <= '1';
        fifo_write_data(1 downto 0) <= MATRIX_MULTIPLY;
        fifo_write_data(31 downto 17) <= std_logic_vector(to_unsigned(SIZE, 15));
        fifo_write_data(16 downto 2) <= std_logic_vector(to_unsigned(SIZE * 3, 15));
        wait for CLK_PERIOD;
        fifo_write_enable <= '0';

        fifo_write_enable <= '1';
        fifo_write_data(1 downto 0) <= MATRIX_MULTIPLY;
        fifo_write_data(31 downto 17) <= std_logic_vector(to_unsigned(0, 15));
        fifo_write_data(16 downto 2) <= std_logic_vector(to_unsigned(SIZE * 4, 15));
        wait for CLK_PERIOD;
        fifo_write_enable <= '0';

        wait for CLK_PERIOD * SIZE * SIZE * SIZE;
        
        -- Read data from unified buffer
        unified_buffer_master_enable <= '1';
        for i in 0 to (SIZE - 1) loop
            unified_buffer_master_read_address <= i + SIZE * 2;
            wait for CLK_PERIOD * 4;
            report_array(unified_buffer_master_read_data);
        end loop;
        unified_buffer_master_enable <= '0';

        wait for CLK_PERIOD * 5;
        report_line("");

        -- Read data from unified buffer
        unified_buffer_master_enable <= '1';
        for i in 0 to (SIZE - 1) loop
            unified_buffer_master_read_address <= i + SIZE * 3;
            wait for CLK_PERIOD * 4;
            report_array(unified_buffer_master_read_data);
        end loop;
        unified_buffer_master_enable <= '0';

        wait for CLK_PERIOD * 5;
        report_line("");

        -- Read data from unified buffer
        unified_buffer_master_enable <= '1';
        for i in 0 to (SIZE - 1) loop
            unified_buffer_master_read_address <= i + SIZE * 4;
            wait for CLK_PERIOD * 4;
            report_array(unified_buffer_master_read_data);
        end loop;
        unified_buffer_master_enable <= '0';

        wait for CLK_PERIOD * 20;

        stop;
    end process;

end architecture;