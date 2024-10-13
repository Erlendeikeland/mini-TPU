library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity systolicarray_tb is
end entity systolicarray_tb;

architecture behave of systolicarray_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '0';

    constant SIZE : integer := 4;

    signal enable : std_logic := '1';
    signal data_in : data_vector_t(0 to SIZE - 1) := (others => (others => '0'));
    signal data_out : data_vector_t(0 to SIZE - 1) := (others => (others => '0'));
    signal weight : weight_vector_t(0 to SIZE - 1) := (others => (others => '0'));

begin

    systolicarray_inst: entity work.systolicarray
        generic map(
            SIZE => SIZE
        )
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


        wait;
    end process;

end architecture;