library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity accumulator_control is
    port (
        clk : in std_logic;
        reset : in std_logic;
        
        op_accumulator_address : in natural;
        op_enable : in std_logic;

        busy : out std_logic;

        accumulator_accumulate : out std_logic;
        accumulator_write_address : out natural;
        accumulator_write_enable : out std_logic
    );
end entity accumulator_control;

architecture rtl of accumulator_control is

    type state_t is (IDLE, LOAD);
    signal state : state_t;
    
    signal counter : natural;
        
    signal current_accumulator_address : natural;

begin

    accumulator_accumulate <= '0';

    process (clk, reset)
    begin
        if reset = '0' then
            state <= IDLE;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if op_enable = '1' then
                        state <= LOAD;
                        current_accumulator_address <= op_accumulator_address;
                        counter <= 0;
                    end if;

                when LOAD =>
                    if counter < (SIZE - 1) then
                        counter <= counter + 1;
                    else
                        if op_enable = '1' then
                            state <= LOAD;
                            current_accumulator_address <= op_accumulator_address;
                            counter <= 0;
                        else
                            state <= IDLE;
                        end if;
                    end if;
            
                when others =>
                    null;
            end case;
        end if;
    end process;

    busy <= '1' when op_enable = '1' or state = LOAD else '0';

    accumulator_write_enable <= '1' when (state = LOAD) and (counter < SIZE - 1) else '0';
    accumulator_write_address <= current_accumulator_address + counter when (counter < SIZE);

end architecture;