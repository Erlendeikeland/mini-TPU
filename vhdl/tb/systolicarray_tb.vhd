library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity systolicarray_tb is
end entity systolicarray_tb;

architecture behave of systolicarray_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk : std_logic := '0';
    signal enable : std_logic := '0';
    signal data_in : vector_signal;
    signal data_out : vector_signal;
    signal weight : std_logic_vector((INTEGER_WIDTH - 1) downto 0);

    type data_array is array(0 to 6, 0 to 2) of integer;
    signal data : data_array := (
        (1, 0, 0),
        (2, 4, 0),
        (3, 5, 7),
        (0, 6, 8),
        (0, 0, 9),
        (0, 0, 0),
        (0, 0, 0)
    );

begin

    systolicarray_inst: entity work.systolicarray
    port map(
        clk => clk,
        enable => enable,
        data_in => data_in,
        data_out => data_out,
        weight => weight
    );

    process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    process
    begin
        enable <= '0';
        weight <= "00000010";
        data_in <= (others => (others => '0'));

        wait for CLK_PERIOD * 5;

        enable <= '1';
        
        for i in 0 to 6 loop
            for j in 0 to 2 loop
                data_in(j) <= std_logic_vector(to_unsigned(data(i, j), INTEGER_WIDTH));
            end loop;

            wait for CLK_PERIOD;
        end loop;

        enable <= '0';

        wait;

    end process;

end architecture;