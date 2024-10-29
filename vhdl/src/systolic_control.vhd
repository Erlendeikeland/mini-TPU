library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity systolic_control is
    port (
        clk : in std_logic;
        reset : in std_logic;
        
        op_unified_buffer_address : in natural;
        op_enable : in std_logic;

        busy : out std_logic;

        unified_buffer_enable : out std_logic;
        unified_buffer_read_address : out natural
    );
end entity systolic_control;

architecture rtl of systolic_control is

    type state_t is (IDLE, LOAD);
    signal state : state_t;
    
    signal counter : natural;
    
    signal current_unified_buffer_address : natural;

begin

    process (clk, reset)
    begin
        if reset = '0' then
            state <= IDLE;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if op_enable = '1' then
                        state <= LOAD;
                        current_unified_buffer_address <= op_unified_buffer_address;
                        counter <= 0;
                    end if;

                when LOAD =>
                    if counter < SIZE then
                        counter <= counter + 1;
                    else
                        state <= IDLE;
                    end if;
            
                when others =>
                    null;
            end case;
        end if;
    end process;

    busy <= '1' when op_enable = '1' or state = LOAD else '0';

    unified_buffer_enable <= '1' when (state = LOAD) and (counter < SIZE) else '0';
    unified_buffer_read_address <= current_unified_buffer_address + counter when (counter < SIZE);

end architecture;