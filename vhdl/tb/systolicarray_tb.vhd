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
    signal data_matrix : matrix_t;
    signal weight_matrix : matrix_t;
    signal expected_matrix : matrix_t;
    signal result : matrix_t;
    
    signal test : natural := 0;

    signal start : std_logic := '0';

    procedure calculate_expected_matrix(
        constant data_matrix : in matrix_t;
        constant weight_matrix : in matrix_t;
        signal expected_matrix : out matrix_t
    ) is
        variable temp_matrix :  matrix_t;
    begin
        for i in 0 to (SIZE - 1) loop
            for j in 0 to (SIZE - 1) loop
                temp_matrix(i, j) := 0;
                for k in 0 to (SIZE - 1) loop
                    temp_matrix(i, j) := temp_matrix(i, j) + data_matrix(i, k) * weight_matrix(k, j);
                end loop;
            end loop;
        end loop;
        expected_matrix <= temp_matrix;
    end procedure;

    procedure set_weights(
        constant weight_matrix : in matrix_t;
        signal weights : out weight_array;
        signal weight_addr : out natural range 0 to (SIZE - 1);
        signal load_weight : out std_logic
    ) is
    begin
        load_weight <= '1';
        for i in 0 to (SIZE - 1) loop
            for j in 0 to (SIZE - 1) loop
                weights(j) <= std_logic_vector(to_unsigned(weight_matrix(i, j), WEIGHT_WIDTH));
            end loop;
            weight_addr <= i;
            wait for CLK_PERIOD;
        end loop;
        load_weight <= '0';
    end procedure;

    procedure multiply_matrix(
        constant data_matrix : in matrix_t;
        signal enable : out std_logic;
        signal start : out std_logic;
        signal data_in : out data_array;
        signal test : out natural
    ) is
    begin
        enable <= '1';
        for i in 0 to (SIZE * 3 - 3) loop
            if i = SIZE + 1 then
                start <= '1';
            else
                start <= '0';
            end if;
            for j in 0 to (SIZE - 1) loop
                test <= test + 1;
                if i - j >= 0 and i - j < SIZE then
                    data_in(j) <= std_logic_vector(to_unsigned(data_matrix(i - j, j), DATA_WIDTH));
                else
                    data_in(j) <= (others => '0');
                end if;
            end loop;
            wait for CLK_PERIOD;
        end loop;
        enable <= '0';
    end procedure;

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

        data_matrix <= (
            (1, 2, 3, 4, 5, 6, 7, 8),
            (9, 10, 11, 12, 13, 14, 15, 16),
            (17, 18, 19, 20, 21, 22, 23, 24),
            (25, 26, 27, 28, 29, 30, 31, 32),
            (33, 34, 35, 36, 37, 38, 39, 40),
            (41, 42, 43, 44, 45, 46, 47, 48),
            (49, 50, 51, 52, 53, 54, 55, 56),
            (57, 58, 59, 60, 61, 62, 63, 64)
        );

        weight_matrix <= (
            (1, 2, 3, 4, 5, 6, 7, 8),
            (9, 10, 11, 12, 13, 14, 15, 16),
            (17, 18, 19, 20, 21, 22, 23, 24),
            (25, 26, 27, 28, 29, 30, 31, 32),
            (33, 34, 35, 36, 37, 38, 39, 40),
            (41, 42, 43, 44, 45, 46, 47, 48),
            (49, 50, 51, 52, 53, 54, 55, 56),
            (57, 58, 59, 60, 61, 62, 63, 64)
        );

        wait for CLK_PERIOD * 2;

        calculate_expected_matrix(data_matrix, weight_matrix, expected_matrix);
        set_weights(weight_matrix, weights, weight_addr, load_weight);
        multiply_matrix(data_matrix, enable, start, data_in, test);

        wait;
    end process;

    process
        variable errors : natural := 0;
    begin
        wait until start = '1';
        for i in 0 to (SIZE * 2 - 1) loop
            for j in 0 to (SIZE - 1) loop
                if i - j >= 0 and i - j < SIZE then
                    result(i - j, j) <= to_integer(unsigned(data_out(j)));
                end if;
            end loop;
            wait for CLK_PERIOD;
        end loop;

        for i in 0 to (SIZE - 1) loop
            for j in 0 to (SIZE - 1) loop
                if result(i, j) /= expected_matrix(i, j) then
                    errors := errors + 1;
                end if;
            end loop;
        end loop;

        if errors /= 0 then
            report_line("Test failed with " & integer'image(errors) & " out of " & integer'image(SIZE * SIZE) & " errors.");
        end if;
    end process;

end architecture;