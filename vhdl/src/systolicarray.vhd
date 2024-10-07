-- Systolic Array
-- Matrix of processing elements (PEs) arranged in a grid
-- Weights are stationary and are stored in the PEs

library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity systolicarray is
    port (
        clk : in std_logic;
        
        enable : in std_logic;

        data_in : in vector_signal;
        data_out : out vector_signal;

        weight : in std_logic_vector((INTEGER_WIDTH - 1) downto 0)
    );
end entity systolicarray;

architecture behave of systolicarray is

    -- Accumulated signal between PEs, are shifted downwards. PE(i, j).accum_out => PE(i + 1, j).accum_in
    signal accum : matrix_signal;
    -- Data signal between PEs, are shifted to the right. PE(i, j).data_out => PE(i, j + 1).data_in
    signal data : matrix_signal;

begin

    -- Instantiate matrix of processing elements
    systolic_array_i_gen : for x in 0 to (WIDTH - 1) generate
        systolic_array_j_gen : for y in 0 to (WIDTH - 1) generate
            -- Upper left corner
            upper_left : if x = 0 and y = 0 generate
                PE_inst : entity work.PE
                    generic map (
                        x => x,
                        y => y
                    )
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
            upper_row : if x = 0 and y > 0 generate
                PE_inst : entity work.PE
                    generic map (
                        x => x,
                        y => y
                    )
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
            left_column : if x > 0 and y = 0 generate
                PE_inst : entity work.PE
                    generic map (
                        x => x,
                        y => y
                    )
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
            remaining : if x > 0 and y > 0 generate
                PE_inst : entity work.PE
                    generic map (
                        x => x,
                        y => y
                    )
                    port map (
                        clk => clk,
                        enable => enable,
                        data_in => data(x - 1, y),
                        data_out => data(x, y),
                        accum_in => accum(x, y - 1),
                        accum_out => accum(x, y),
                        weight => weight
                    );
            end generate;
        end generate;
    end generate;

    -- Output data from the last PE
    process (all)
    begin
        for i in 0 to (WIDTH - 1) loop
            data_out(i) <= data(i, WIDTH - 1);
        end loop;
    end process;

end architecture;