library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.env.stop;

use work.minitpu_pkg.all;


entity systolic_array_tb is
end entity systolic_array_tb;

architecture behave of systolic_array_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';

    signal enable : std_logic := '0';
    signal data_in : data_array := (others => (others => '0'));
    signal data_out : output_array := (others => (others => '0'));

    signal weight_in : weight_array := (others => (others => '0'));
    signal weight_address : natural range 0 to (SIZE - 1) := 0;
    signal weight_enable : std_logic := '0';

    type matrix_t is array (0 to (SIZE - 1), 0 to (SIZE - 1)) of natural;
    signal data_matrix : matrix_t;
    signal weight_matrix : matrix_t;
    
    signal start : std_logic := '0';

    procedure set_weights(
        constant weight_matrix : in matrix_t;
        signal weight_in : out weight_array;
        signal weight_address : out natural range 0 to (SIZE - 1);
        signal weight_enable : out std_logic
    ) is
    begin
        weight_enable <= '1';
        for i in 0 to (SIZE - 1) loop
            for j in 0 to (SIZE - 1) loop
                weight_in(j) <= std_logic_vector(to_unsigned(weight_matrix(i, j), WEIGHT_WIDTH));
            end loop;
            weight_address <= i;
            wait for CLK_PERIOD;
        end loop;
        weight_enable <= '0';
    end procedure;

    procedure multiply_matrix(
        constant data_matrix : in matrix_t;
        signal enable : out std_logic;
        signal start : out std_logic;
        signal data_in : out data_array
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

    systolic_array_inst: entity work.systolic_array
        port map(
            clk => clk,
            enable => enable,
            data_in => data_in,
            data_out => data_out,
            weight_in => weight_in,
            weight_address => weight_address,
            weight_enable => weight_enable
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        wait for CLK_PERIOD * 2;

        data_matrix <= (
            (1, 2, 3, 4),
            (5, 6, 7, 8),
            (9, 10, 11, 12),
            (13, 14, 15, 16)
        );

        weight_matrix <= (
            (1, 2, 3, 4),
            (5, 6, 7, 8),
            (9, 10, 11, 12),
            (13, 14, 15, 16)
        );

        wait for CLK_PERIOD * 2;

        set_weights(weight_matrix, weight_in, weight_address, weight_enable);
        multiply_matrix(data_matrix, enable, start, data_in);

        wait for CLK_PERIOD * 10;

        stop;

        wait;
    end process;

end architecture;