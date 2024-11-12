library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity control is
    port (
        clk : in std_logic;
        reset : in std_logic;

        fifo_empty : in std_logic;
        fifo_read_enable : out std_logic;
        fifo_read_data : in op_t;

        weight_buffer_port_1_enable : out std_logic;
        weight_buffer_port_1_read_address : out natural range 0 to (WEIGHT_BUFFER_DEPTH - 1);
        
        unified_buffer_port_0_enable : out std_logic;
        unified_buffer_port_0_write_address : out natural range 0 to (UNIFIED_BUFFER_DEPTH - 1);
        unified_buffer_port_0_write_enable : out std_logic;
        unified_buffer_port_1_enable : out std_logic;
        unified_buffer_port_1_read_address : out natural range 0 to (UNIFIED_BUFFER_DEPTH - 1);
        
        systolic_array_weight_address : out natural range 0 to (SIZE - 1);
        systolic_array_weight_enable : out std_logic;
        
        accumulator_accumulate : out std_logic;
        accumulator_write_address : out natural range 0 to (ACCUMULATOR_DEPTH - 1);
        accumulator_write_enable : out std_logic;
        accumulator_read_address : out natural range 0 to (ACCUMULATOR_DEPTH - 1)
    );
end entity control;

architecture behave of control is

    type state_t is (IDLE, RUNNING);
    signal state : state_t;

    signal op_reg_0 : op_t;
    signal op_reg_1 : op_t;
    signal op_reg_2 : op_t;

    signal weight_buffer_count : natural range 0 to (WEIGHT_BUFFER_DEPTH - 1);
    signal weight_buffer_count_enable : std_logic;

    signal unified_buffer_read_count : natural range 0 to (UNIFIED_BUFFER_DEPTH - 1);
    signal unified_buffer_read_count_enable : std_logic;

    signal unified_buffer_write_count : natural range 0 to (UNIFIED_BUFFER_DEPTH - 1);
    signal unified_buffer_write_count_enable : std_logic;
    

    signal systolic_enable_shift : std_logic_vector(((SIZE - 1) + DELAY_3) downto 0);
    signal systolic_enable : std_logic;
    signal weight_buffer_enable_shift : std_logic_vector(((SIZE - 1) + WEIGHT_BUFFER_READ_DELAY) downto 0);
    signal weight_buffer_enable : std_logic;

    signal systolic_busy : std_logic;

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                state <= IDLE;
                systolic_enable <= '0';
                weight_buffer_enable <= '0';
                fifo_read_enable <= '0';
            else
                case state is
                    when IDLE =>
                        if fifo_empty = '0' then
                            if fifo_read_data(1 downto 0) = LOAD_WEIGHTS then
                                if systolic_busy = '0' then
                                    state <= RUNNING;
                                    fifo_read_enable <= '1';
                                    op_reg_0 <= fifo_read_data;
                                    weight_buffer_enable <= '1';
                                end if;
                            elsif fifo_read_data(1 downto 0) = MATRIX_MULTIPLY then
                                state <= RUNNING;
                                fifo_read_enable <= '1';
                                op_reg_0 <= fifo_read_data;
                                systolic_enable <= '1';
                            end if;
                        end if;

                    when RUNNING =>
                        fifo_read_enable <= '0';
                        systolic_enable <= '0';
                        weight_buffer_enable <= '0';

                        if op_reg_0(1 downto 0) = LOAD_WEIGHTS then
                            if weight_buffer_enable_shift((SIZE - 1) + WEIGHT_BUFFER_READ_DELAY) = '1' then
                                state <= IDLE;
                            end if;
                        elsif op_reg_0(1 downto 0) = MATRIX_MULTIPLY then
                            if systolic_enable_shift((SIZE - 2) + UNIFIED_BUFFER_READ_DELAY) = '1' then
                                state <= IDLE;
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                systolic_enable_shift <= (others => '0');
                weight_buffer_enable_shift <= (others => '0');
            else
                systolic_enable_shift <= systolic_enable_shift((systolic_enable_shift'high - 1) downto 0) & systolic_enable;
                weight_buffer_enable_shift <= weight_buffer_enable_shift((weight_buffer_enable_shift'high - 1) downto 0) & weight_buffer_enable;
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if systolic_enable_shift(SIZE - 1 + SYSTOLIC_SETUP_DELAY) = '1' then
                op_reg_1(31 downto 17) <= op_reg_0(31 downto 17);
                op_reg_1(16 downto 2) <= op_reg_0(16 downto 2);
            end if;

            if systolic_enable_shift(DELAY_2) = '1' then
                op_reg_2(31 downto 17) <= op_reg_1(31 downto 17);
                op_reg_2(16 downto 2) <= op_reg_1(16 downto 2);
            end if;
        end if;
    end process;

    process (all)
    begin
        weight_buffer_port_1_enable <= '0';
        systolic_array_weight_enable <= '0';
        systolic_array_weight_address <= 0;

        for i in 0 to (SIZE - 1) loop
            if weight_buffer_enable_shift(i) = '1' then
                weight_buffer_port_1_enable <= '1';
            end if;

            if weight_buffer_enable_shift(i + WEIGHT_BUFFER_READ_DELAY) = '1' then
                systolic_array_weight_enable <= '1';
                systolic_array_weight_address <= i;
            end if;
        end loop;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if weight_buffer_count_enable = '1' then
                weight_buffer_count <= weight_buffer_count + 1;
            elsif weight_buffer_enable = '1' then
                weight_buffer_count <= to_integer(unsigned(op_reg_0(31 downto 2)));
            end if;
        end if;
    end process;

    weight_buffer_count_enable <= or weight_buffer_enable_shift((SIZE - 2) downto 0);
    weight_buffer_port_1_read_address <= weight_buffer_count;

    process (all)
    begin
        unified_buffer_port_1_enable <= '0';

        accumulator_accumulate <= '0';
        accumulator_write_address <= 0;
        accumulator_write_enable <= '0';

        accumulator_read_address <= 0;

        unified_buffer_port_0_enable <= '0';
        unified_buffer_port_0_write_enable <= '0';

        for i in 0 to (SIZE - 1) loop
            if systolic_enable_shift(i) = '1' then
                unified_buffer_port_1_enable <= '1';
            end if;

            if systolic_enable_shift(i + DELAY_1) = '1' then
                accumulator_write_enable <= '1';
                accumulator_write_address <= i;
            end if;

            if systolic_enable_shift(i + DELAY_2) = '1' then
                accumulator_read_address <= i;
            end if;

            if systolic_enable_shift(i + DELAY_3) = '1' then
                unified_buffer_port_0_enable <= '1';
                unified_buffer_port_0_write_enable <= '1';
            end if;
        end loop;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if unified_buffer_read_count_enable = '1' then
                unified_buffer_read_count <= unified_buffer_read_count + 1;
            elsif systolic_enable = '1' then
                unified_buffer_read_count <= to_integer(unsigned(op_reg_0(31 downto 17)));
            end if;
        end if;
    end process;

    unified_buffer_read_count_enable <= or systolic_enable_shift((SIZE - 2) downto 0);
    unified_buffer_port_1_read_address <= unified_buffer_read_count;

    process (clk)
    begin
        if rising_edge(clk) then
            if unified_buffer_write_count_enable = '1' then
                unified_buffer_write_count <= unified_buffer_write_count + 1;
            elsif systolic_enable_shift(DELAY_3 - 1) = '1' then
                unified_buffer_write_count <= to_integer(unsigned(op_reg_2(16 downto 2)));
            end if;
        end if;
    end process;

    unified_buffer_write_count_enable <= or systolic_enable_shift(DELAY_3 + (SIZE - 2) downto DELAY_3);
    unified_buffer_port_0_write_address <= unified_buffer_write_count;

    process (all)
    begin
        for i in 0 to ((SIZE * 2) - 5) loop
            if systolic_enable_shift(i) = '1' then
                systolic_busy <= '1';
                exit;
            else
                systolic_busy <= '0';
            end if;
        end loop;
    end process;

end architecture;