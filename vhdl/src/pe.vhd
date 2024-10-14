-- Processing Element (PE)
-- Performs a multiply accumulate operation, acc_out = acc_in + (data_in * weight)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity PE is
    generic (
        ACCUM_IN_WIDTH : natural;
        ACCUM_OUT_WIDTH : natural
    );
    port (
        clk : in std_logic;
        enable : in std_logic;
        data_in : in std_logic_vector((DATA_WIDTH - 1) downto 0);
        data_out : out std_logic_vector((DATA_WIDTH - 1) downto 0);
        accum_in : in std_logic_vector((ACCUM_IN_WIDTH - 1) downto 0);
        accum_out : out std_logic_vector((ACCUM_OUT_WIDTH - 1) downto 0);
        weight : in std_logic_vector((WEIGHT_WIDTH - 1) downto 0);
        load_weight : in std_logic
    );
end entity PE;

architecture behave of PE is

    signal weight_reg : std_logic_vector((WEIGHT_WIDTH - 1) downto 0);

begin

    -- Set weight register
    process(clk)
    begin
        if rising_edge(clk) then
            if load_weight = '1' then
                weight_reg <= weight;
            end if;
        end if;
    end process;

    -- Perform multiply accumulate operation
    process(clk)
        variable product : std_logic_vector(((DATA_WIDTH + WEIGHT_WIDTH) - 1) downto 0);
        variable sum : std_logic_vector((ACCUM_OUT_WIDTH - 1) downto 0);
    begin
        if rising_edge(clk) then
            if enable = '1' then
                product := std_logic_vector(unsigned(data_in) * unsigned(weight_reg));
                
                if (ACCUM_IN_WIDTH > 0) and (ACCUM_IN_WIDTH < ACCUM_OUT_WIDTH) then
                    -- Output width is greater than input width, zero extend input
                    sum := std_logic_vector(unsigned('0' & accum_in) + unsigned('0' & product));
                elsif (ACCUM_IN_WIDTH > 0) and (ACCUM_IN_WIDTH = ACCUM_OUT_WIDTH) then
                    -- Output width is equal to input width
                    sum := std_logic_vector(unsigned(accum_in) + unsigned(product));
                else
                    -- Input width is zero, accumulator input is ignored
                    sum := product;
                end if;

                accum_out <= sum;
                data_out <= data_in;
            end if;
        end if;
    end process;

end architecture;