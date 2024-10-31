library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity control is
    port (
        clk : in std_logic;
        reset : in std_logic;

        fifo_empty : in std_logic;
        fifo_read_enable : out std_logic;
        fifo_read_data : in op_t;

        weight_buffer_port_1_enable : out std_logic;
        weight_buffer_port_1_read_address : out natural;
        
        unified_buffer_port_0_enable : out std_logic;
        unified_buffer_port_0_write_address : out natural;
        unified_buffer_port_0_write_enable : out std_logic;
        unified_buffer_port_1_enable : out std_logic;
        unified_buffer_port_1_read_address : out natural;
        
        systolic_array_weight_address : out natural;
        systolic_array_weight_enable : out std_logic;
        
        accumulator_accumulate : out std_logic;
        accumulator_write_address : out natural;
        accumulator_write_enable : out std_logic;
        accumulator_read_address : out natural
    );
end entity control;

architecture behave of control is

    type state_t is (IDLE, RUNNING);
    signal state : state_t;

    signal op_reg_0 : op_t;
    signal op_reg_1 : op_t;
    signal op_reg_2 : op_t;

    signal systolic_enable_shift : std_logic_vector((SIZE * 3) downto 0);
    signal systolic_enable : std_logic;
    signal weight_buffer_enable_shift : std_logic_vector((SIZE + 1) downto 0);
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
                            if fifo_read_data.op_code = LOAD_WEIGHTS then
                                if systolic_busy = '0' then
                                    state <= RUNNING;
                                    fifo_read_enable <= '1';
                                    op_reg_0 <= fifo_read_data;
                                    weight_buffer_enable <= '1';
                                end if;
                            elsif fifo_read_data.op_code = MATRIX_MULTIPLY then
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

                        if op_reg_0.op_code = LOAD_WEIGHTS then
                            if weight_buffer_enable_shift(SIZE + 1) = '1' then
                                state <= IDLE;
                            end if;
                        elsif op_reg_0.op_code = MATRIX_MULTIPLY then
                            if systolic_enable_shift(SIZE - 2) = '1' then
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
            if systolic_enable_shift(SIZE - 1) = '1' then
                op_reg_1.unified_buffer_address <= op_reg_0.unified_buffer_address;
                op_reg_1.accumulator_address <= op_reg_0.accumulator_address;
            end if;

            if systolic_enable_shift((SIZE * 2) - 1) = '1' then
                op_reg_2.unified_buffer_address <= op_reg_1.unified_buffer_address;
                op_reg_2.accumulator_address <= op_reg_1.accumulator_address;
            end if;
        end if;
    end process;

    process (all)
    begin
        weight_buffer_port_1_enable <= '0';
        weight_buffer_port_1_read_address <= 0;
        systolic_array_weight_enable <= '0';
        systolic_array_weight_address <= 0;

        for i in 0 to (SIZE - 1) loop
            if weight_buffer_enable_shift(i) = '1' then
                weight_buffer_port_1_enable <= '1';
                weight_buffer_port_1_read_address <= op_reg_0.weight_buffer_address + i;
            end if;
        end loop;

        for i in 1 to SIZE loop
            if weight_buffer_enable_shift(i) = '1' then
                systolic_array_weight_enable <= '1';
                systolic_array_weight_address <= i - 1;
            end if;
        end loop;
    end process;

    process (all)
    begin
        unified_buffer_port_1_enable <= '0';
        unified_buffer_port_1_read_address <= 0;

        accumulator_accumulate <= '0';
        accumulator_write_address <= 0;
        accumulator_write_enable <= '0';

        accumulator_read_address <= 0;

        unified_buffer_port_0_enable <= '0';
        unified_buffer_port_0_write_address <= 0;
        unified_buffer_port_0_write_enable <= '0';

        for i in 0 to (SIZE - 1) loop
            if systolic_enable_shift(i) = '1' then
                unified_buffer_port_1_enable <= '1';
                unified_buffer_port_1_read_address <= op_reg_0.unified_buffer_address + i;
            end if;
        end loop;

        for i in (SIZE + 1) to (SIZE * 2) loop
            if systolic_enable_shift(i) = '1' then
                accumulator_write_enable <= '1';
                accumulator_write_address <= i - (SIZE + 1);
            end if;
        end loop;

        for i in (SIZE * 2) to ((SIZE * 3) - 1) loop
            if systolic_enable_shift(i) = '1' then
                accumulator_read_address <= i - (SIZE * 2);
            end if;
        end loop;

        for i in ((SIZE * 2) + 1) to (SIZE * 3) loop
            if systolic_enable_shift(i) = '1' then
                unified_buffer_port_0_enable <= '1';
                unified_buffer_port_0_write_enable <= '1';
                unified_buffer_port_0_write_address <= op_reg_2.accumulator_address + i - ((SIZE * 2) + 1);
            end if;
        end loop;
    end process;

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