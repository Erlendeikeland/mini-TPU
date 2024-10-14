library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.minitpu_pkg.all;

entity systolicarray_tb is
end entity systolicarray_tb;

architecture behave of systolicarray_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';

    signal enable : std_logic := '0';
    signal data_in : data_array := (others => (others => '0'));
    signal data_out : output_vector_t(0 to (SIZE - 1)) := (others => (others => '0'));

    signal weights : weight_array := (others => (others => '0'));
    signal weight_addr : natural range 0 to (SIZE - 1) := 0;
    signal load_weight : std_logic := '0';

    type matrix_t is array (0 to (SIZE - 1), 0 to (SIZE - 1)) of natural;
    signal data_matrix : matrix_t := (
        (255, 255, 255),
        (255, 255, 255),
        (255, 255, 255)
    );

    signal weight_matrix : matrix_t := (
        (255, 255, 255),
        (255, 255, 255),
        (255, 255, 255)
    );

    signal expected_matrix : matrix_t := (
        (195075, 195075, 195075),
        (195075, 195075, 195075),
        (195075, 195075, 195075)
    );

    signal result : matrix_t;
    signal start : std_logic := '0';

begin

    systolicarray_inst: entity work.systolicarray
        port map(
            clk => clk,
            enable => enable,
            data_in => data_in,
            data_out => data_out,
            weights => weights,
            weight_addr => weight_addr,
            load_weights => load_weight
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        wait for CLK_PERIOD * 2;

        load_weight <= '1';
        
        for i in 0 to (SIZE - 1) loop
            for j in 0 to (SIZE - 1) loop
                weights(j) <= std_logic_vector(to_unsigned(weight_matrix(i, j), WEIGHT_WIDTH));
            end loop;
            weight_addr <= i;
            wait for CLK_PERIOD;
        end loop;

        load_weight <= '0';

        enable <= '1';

        for i in 0 to (SIZE * 2) loop
            if i > SIZE then
                start <= '1';
            end if;
            for j in 0 to (SIZE - 1) loop
                if i - j >= 0 and i - j < SIZE then
                    data_in(j) <= std_logic_vector(to_unsigned(data_matrix(i - j, j), DATA_WIDTH));
                else
                    data_in(j) <= (others => '0');
                end if;
            end loop;
            wait for CLK_PERIOD;
        end loop;

        enable <= '0';

        wait;
    end process;

    process
    begin
        -- Wait until start signal to start sampling data_out
        -- Each column will be delayed by n cycles, where n is the column number
        wait until start = '1';
        for i in 0 to (SIZE * 2 - 1) loop
            for j in 0 to (SIZE - 1) loop
                if i - j >= 0 and i - j < SIZE then
                    result(i - j, j) <= to_integer(unsigned(data_out(j)));
                end if;
            end loop;
            wait for CLK_PERIOD;
        end loop;

        assert result = expected_matrix report "Mismatch between expected and actual results" severity error;
    end process;

end architecture;