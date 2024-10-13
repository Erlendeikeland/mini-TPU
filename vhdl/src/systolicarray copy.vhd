-- Systolic Array
-- Matrix of processing elements (PEs) arranged in a grid
-- Weights are stationary and are stored in the PEs

library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity systolicarray1 is
    generic (
        SIZE : integer
    );
    port (
        clk : in std_logic;
        enable : in std_logic;
        data_in : in vector_t;
        data_out : out vector_t;
        weight : in data_t
    );
end entity systolicarray1;

architecture behave of systolicarray1 is

    -- Signals for passing data, and accumulated values between PEs
    signal accum : matrix_t;
    signal data : matrix_t;

begin

    -- Instantiate matrix of processing elements
    systolic_array_i_gen : for x in 0 to (SIZE - 1) generate
        systolic_array_j_gen : for y in 0 to (SIZE - 1) generate
            -- Upper left corner
            upper_left_if : if x = 0 and y = 0 generate
                PE_inst : entity work.PE
                    port map (
                        clk => clk,
                        enable => enable,
                        data_in => data_in(x),
                        data_out => data(x, y),
                        accum_in => (others => '0'),
                        accum_out => accum(x, y),
                        weight => weight
                    );
            end generate;

            -- Upper row
            upper_row_if : if x = 0 and y > 0 generate
                PE_inst : entity work.PE
                    port map (
                        clk => clk,
                        enable => enable,
                        data_in => data(x, y - 1),
                        data_out => data(x, y),
                        accum_in => (others => '0'),
                        accum_out => accum(x, y),
                        weight => weight
                    );
            end generate;

            -- Left column
            left_column_if : if x > 0 and y = 0 generate
                PE_inst : entity work.PE
                    port map (
                        clk => clk,
                        enable => enable,
                        data_in => data_in(x),
                        data_out => data(x, y),
                        accum_in => accum(x - 1, y),
                        accum_out => accum(x, y),
                        weight => weight
                    );
            end generate;

            -- Remaining PEs
            remaining_if : if x > 0 and y > 0 generate
                PE_inst : entity work.PE
                    port map (
                        clk => clk,
                        enable => enable,
                        data_in => data(x, y - 1),
                        data_out => data(x, y),
                        accum_in => accum(x - 1, y),
                        accum_out => accum(x, y),
                        weight => weight
                    );
            end generate;
        end generate;
    end generate;

    -- Output accumulated value of bottom row of PEs
    process (all)
    begin
        for i in 0 to (SIZE - 1) loop
            data_out(i) <= accum(SIZE - 1, i);
        end loop;
    end process;

end architecture;