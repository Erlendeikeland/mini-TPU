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

    -- Main control
    type fifo_state_t is (IDLE, READ_DATA, WAIT_BUSY);
    signal fifo_state : fifo_state_t;

    signal current_op : op_t;

    -- Weight control
    type weight_state_t is (IDLE, WRITE_WEIGHTS);
    signal weight_state : weight_state_t;

    signal weight_enable : std_logic;
    signal weight_counter : natural;
    signal weight_done : std_logic;

    -- Systolic array control
    type systolic_state_t is (IDLE, MULTIPLY);
    signal systolic_state : systolic_state_t;

    signal systolic_enable : std_logic;
    signal systolic_counter : natural;
    signal systolic_done : std_logic;

    -- Accumulator control
    type accumulator_state_t is (IDLE, ACCUMULATE);
    signal accumulator_state : accumulator_state_t;

    signal accumulator_address : natural;
    signal accumulator_counter : natural;

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
            else
                case fifo_state is
                    when IDLE =>
                        if fifo_empty = '0' then
                            fifo_read_enable <= '1';
                            current_op <= fifo_read_data;
                            fifo_state <= READ_DATA;
                        end if;

                    when READ_DATA =>
                        fifo_read_enable <= '0';
                        case current_op.op_code is
                            when LOAD_WEIGHTS =>
                                if weight_state = IDLE then
                                    weight_enable <= '1';
                                end if;

                            when MATRIX_MULTIPLY =>
                                if systolic_state = IDLE then
                                    systolic_enable <= '1';
                                end if;
                                
                            when others =>
                                null;
                        end case;
                        fifo_state <= WAIT_BUSY;

                    when WAIT_BUSY =>
                        weight_enable <= '0';
                        systolic_enable <= '0';
                        if weight_done = '1' or systolic_done = '1' then
                            fifo_state <= IDLE;
                        end if;
                        
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                weight_state <= IDLE;
                weight_counter <= 0;
            else
                case weight_state is
                    when IDLE =>
                        weight_done <= '0';
                        if weight_enable = '1' then
                            weight_counter <= 0;
                            weight_state <= WRITE_WEIGHTS;
                        end if;

                    when WRITE_WEIGHTS =>
                        if weight_counter = SIZE then
                            weight_done <= '1';
                            weight_state <= IDLE;
                        else
                            weight_counter <= weight_counter + 1;
                        end if;
                    
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    weight_buffer_port_1_enable <= '1' when (weight_state = WRITE_WEIGHTS) and (weight_counter < SIZE) else '0';
    weight_buffer_port_1_read_address <= current_op.weight_buffer_address + weight_counter when (weight_counter < SIZE);

    systolic_array_weight_enable <= '1' when (weight_state = WRITE_WEIGHTS) and (weight_counter > 0) and (weight_counter < (SIZE + 1)) else '0';
    systolic_array_weight_address <= weight_counter - 1 when (weight_counter > 0) and (weight_counter < (SIZE + 1));

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                systolic_state <= IDLE;
                systolic_counter <= 0;
            else
                case systolic_state is
                    when IDLE =>
                        systolic_done <= '0';
                        if systolic_enable = '1' then
                            systolic_counter <= 0;
                            systolic_state <= MULTIPLY;
                        end if;

                    when MULTIPLY =>
                        if systolic_counter = SIZE then
                            systolic_done <= '1';
                            accumulator_address <= current_op.accumulator_address;
                            systolic_state <= IDLE;
                        else
                            systolic_counter <= systolic_counter + 1;
                        end if;

                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    unified_buffer_port_1_enable <= '1' when (systolic_state = MULTIPLY) and (systolic_counter < SIZE) else '0';
    unified_buffer_port_1_read_address <= current_op.unified_buffer_address + systolic_counter when (systolic_counter < SIZE);

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                accumulator_state <= IDLE;
                accumulator_counter <= 0;
            else
                case accumulator_state is
                    when IDLE =>
                        if systolic_done = '1' then
                            accumulator_counter <= 0;
                            accumulator_state <= ACCUMULATE;
                        end if;

                    when ACCUMULATE =>
                        if accumulator_counter = SIZE then
                            accumulator_state <= IDLE;
                        else
                            accumulator_counter <= accumulator_counter + 1;
                        end if;
                    
                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    accumulator_accumulate <= '0';
    accumulator_write_enable <= '1' when (accumulator_state = ACCUMULATE) and (accumulator_counter < SIZE) else '0';
    accumulator_write_address <= accumulator_address + accumulator_counter when (accumulator_counter < SIZE);

end architecture;