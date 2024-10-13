-- Systolic Array
-- Matrix of processing elements (PEs) arranged in a grid
-- Weights are stationary and are stored in the PEs

library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity systolicarray is
    generic (
        SIZE : integer
    );
    port (
        clk : in std_logic;
        enable : in std_logic;
        data_in : in data_vector_t;
        data_out : out data_vector_t;
        weight : in weight_vector_t
    );
end entity systolicarray;

architecture behave of systolicarray is

begin

    -- Instantiate matrix of processing elements
    systolic_array_x_gen : for x in 0 to (SIZE - 1) generate
        systolic_array_y_gen : for y in 0 to (SIZE - 1) generate
            -- Upper left corner
            upper_left_if : if x = 0 and y = 0 generate
                PE_inst : entity work.PE
                    generic map (
                        ACCUM_IN_WIDTH => 0,
                        ACCUM_OUT_WIDTH => get_accum_width(x)
                    )
                    port map (
                        clk => clk,
                        enable => enable,
                        data_in => (others => '0'),
                        accum_in => (others => '0'),
                        load_weight => '1',
                        weight => weight(y)
                    );
            end generate;

            -- Upper row
            upper_row_if : if x = 0 and y > 0 generate
                PE_inst : entity work.PE
                    generic map (
                        ACCUM_IN_WIDTH => 0,
                        ACCUM_OUT_WIDTH => get_accum_width(x)
                    )
                    port map (
                        clk => clk,
                        enable => enable,
                        data_in => (others => '0'),
                        accum_in => (others => '0'),
                        load_weight => '0',
                        weight => weight(y)
                    );
            end generate;

            -- Left column
            left_column_if : if x > 0 and y = 0 generate
                PE_inst : entity work.PE
                    generic map (
                        ACCUM_IN_WIDTH => get_accum_width(x - 1),
                        ACCUM_OUT_WIDTH => get_accum_width(x)
                    )
                    port map (
                        clk => clk,
                        enable => enable,
                        data_in => (others => '0'),
                        accum_in => (others => '0'),
                        load_weight => '0',
                        weight => weight(y)
                    );
            end generate;

            -- Remaining PEs
            remaining_if : if x > 0 and y > 0 generate
                PE_inst : entity work.PE
                    generic map (
                        ACCUM_IN_WIDTH => get_accum_width(x - 1),
                        ACCUM_OUT_WIDTH => get_accum_width(x)
                    )
                    port map (
                        clk => clk,
                        enable => enable,
                        data_in => (others => '0'),
                        accum_in => (others => '0'),
                        load_weight => '0',
                        weight => weight(y)
                    );
            end generate;
        end generate;
    end generate;

end architecture;