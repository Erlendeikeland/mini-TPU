library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity accumulator is
    generic (
        WIDTH : natural;
        DEPTH : natural
    );
    port (
        clk : in std_logic;
        data_in : in output_array;
        data_out : out output_array
    );
end entity accumulator;

architecture behave of accumulator is

    type shift_data_t is array(0 to (WIDTH - 1)) of output_array;

begin

    process (clk)
        variable shift_data : shift_data_t;
    begin
        if rising_edge(clk) then
            shift_data := data_in & shift_data(0 to (WIDTH - 2));

            for i in 0 to (WIDTH - 1) loop
                data_out(i) <= shift_data((SIZE - 1) - i)(0 + i);
            end loop;
        end if;
    end process;

end architecture;