library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity control is
    port (
        clk : in std_logic;
        reset : in std_logic;

        fifo_full : in std_logic;
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

    signal count : natural range 0 to SIZE + 8;
    signal count_limit : natural range 0 to SIZE + 8;

    signal current_op : op_t;

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                state <= IDLE;
            else
                case state is
                    when IDLE =>
                        if fifo_empty = '0' then
                            state <= RUNNING;
                            fifo_read_enable <= '1';
                            current_op <= fifo_read_data;
                            count <= 0;
                        end if;

                    when RUNNING =>
                        fifo_read_enable <= '0';
                        if count < count_limit then
                            count <= count + 1;
                        else
                            state <= IDLE;
                        end if;

                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    process (all)
    begin
        case current_op.op_code is
            when LOAD_WEIGHTS =>
                count_limit <= SIZE;

            when MATRIX_MULTIPLY =>
                count_limit <= SIZE + 8;

            when others =>
                count_limit <= 0;
        end case;
    end process;

    -- LOAD_WEIGHTS
    weight_buffer_port_1_enable <= '1' when (state = RUNNING) and (count < SIZE) and current_op.op_code = LOAD_WEIGHTS else '0';
    weight_buffer_port_1_read_address <= current_op.weight_buffer_address + count when (count < SIZE) and current_op.op_code = LOAD_WEIGHTS;
        
    systolic_array_weight_enable <= '1' when (state = RUNNING) and (count > 0) and (count < (SIZE + 1)) and current_op.op_code = LOAD_WEIGHTS else '0';
    systolic_array_weight_address <= count - 1 when (count > 0) and (count < (SIZE + 1)) and current_op.op_code = LOAD_WEIGHTS;

    -- MATRIX_MULTIPLY
    unified_buffer_port_1_enable <= '1' when (state = RUNNING) and (count < SIZE) and current_op.op_code = MATRIX_MULTIPLY else '0';
    unified_buffer_port_1_read_address <= current_op.unified_buffer_address + count when (count < SIZE) and current_op.op_code = MATRIX_MULTIPLY;

    accumulator_write_enable <= '1' when (state = RUNNING) and (count > 4) and (count < SIZE + 5) and current_op.op_code = MATRIX_MULTIPLY else '0';
    accumulator_write_address <= count - 5 when (count > 4) and (count < SIZE + 5) and current_op.op_code = MATRIX_MULTIPLY;
    accumulator_accumulate <= '0';

    accumulator_read_address <= count - 8 when (count > 7) and (count < SIZE + 8) and current_op.op_code = MATRIX_MULTIPLY;

    unified_buffer_port_0_enable <= '1' when (state = RUNNING) and (count > 8) and (count < SIZE + 9) and current_op.op_code = MATRIX_MULTIPLY else '0';
    unified_buffer_port_0_write_address <= current_op.accumulator_address + count - 9 when (count > 8) and (count < SIZE + 9) and current_op.op_code = MATRIX_MULTIPLY;
    unified_buffer_port_0_write_enable <= '1' when (state = RUNNING) and (count > 8) and (count < SIZE + 9) and current_op.op_code = MATRIX_MULTIPLY else '0';

end architecture;