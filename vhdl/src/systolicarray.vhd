-- Systolic Array
-- Matrix of processing elements (PEs) arranged in a grid

library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity systolicarray is
    port (
        clk : in std_logic;
        enable : in std_logic;
        data_in : in data_vector_t;
        data_out : out output_vector_t;
        weight : in weight_vector_t;
        load_weight : in std_logic
    );
end entity systolicarray;

architecture behave of systolicarray is

    type data_matrix_t is array (0 to (SIZE - 1), 0 to (SIZE - 1)) of std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal data : data_matrix_t;
    type accum_matrix_t is array (0 to (SIZE - 1), 0 to (SIZE - 1)) of std_logic_vector((get_accum_width(SIZE - 1) - 1) downto 0);
    signal accum : accum_matrix_t;

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
                        data_in => data_in(x),
                        data_out => data(x, y),
                        accum_in => (others => '0'),
                        accum_out => accum(x, y)(get_accum_width(x) - 1 downto 0),
                        load_weight => load_weight,
                        weight => weight(x)
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
                        data_in => data(x, y - 1),
                        data_out => data(x, y),
                        accum_in => (others => '0'),
                        accum_out => accum(x, y)(get_accum_width(x) - 1 downto 0),
                        load_weight => load_weight,
                        weight => weight(x)
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
                        data_in => data_in(x),
                        data_out => data(x, y),
                        accum_in => accum(x - 1, y)(get_accum_width(x - 1) - 1 downto 0),
                        accum_out => accum(x, y)(get_accum_width(x) - 1 downto 0),
                        load_weight => load_weight,
                        weight => weight(x)
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
                        data_in => data(x, y - 1),
                        data_out => data(x, y),
                        accum_in => accum(x - 1, y)(get_accum_width(x - 1) - 1 downto 0),
                        accum_out => accum(x, y)(get_accum_width(x) - 1 downto 0),
                        load_weight => load_weight,
                        weight => weight(x)
                    );
            end generate;
        end generate;
    end generate;

    -- Output data from the last row of PEs
    process (all)
    begin
        for i in 0 to (SIZE - 1) loop
            data_out(i) <= accum(SIZE - 1, i);
        end loop;
    end process;

end architecture;