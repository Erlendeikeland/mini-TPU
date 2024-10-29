library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity weight_control is
    port (
        clk : in std_logic;
        reset : in std_logic;

        op_address : in natural;
        op_enable : in std_logic;

        busy : out std_logic;

        weight_buffer_enable : out std_logic;
        weight_buffer_read_address : out natural;

        systolic_array_weight_enable : out std_logic;
        systolic_array_weight_address : out natural
    );
end entity weight_control;

architecture rtl of weight_control is

    type state_t is (IDLE, LOAD);
    signal state : state_t;

    signal counter : natural;

    signal current_address : natural;

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
                        current_address <= op_address;
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

    weight_buffer_enable <= '1' when (state = LOAD) and (counter < SIZE) else '0';
    weight_buffer_read_address <= current_address + counter when (counter < SIZE);
    
    systolic_array_weight_enable <= '1' when (state = LOAD) and (counter > 0) and (counter < (SIZE + 1)) else '0';
    systolic_array_weight_address <= counter - 1 when (counter > 0) and (counter < (SIZE + 1));

end architecture;
