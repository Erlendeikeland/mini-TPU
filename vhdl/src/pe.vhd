-- Processing Element (PE)
-- Performs a multiply accumulate operation on the input data and weight

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PE is
    generic (
        x : integer := 0;
        y : integer := 0
    );
    port (
        clk : in std_logic;

        enable : in std_logic;

        data_in : in std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0);

        accum_in : in std_logic_vector(7 downto 0);
        accum_out : out std_logic_vector(7 downto 0);

        weight : in std_logic_vector(7 downto 0)
    );
end entity PE;

architecture behave of PE is

begin

    process (clk)
        variable accum : std_logic_vector(15 downto 0);
    begin
        if rising_edge(clk) then
            if enable = '1' then
                accum := std_logic_vector(unsigned(accum_in) + unsigned(data_in) * unsigned(weight));
                accum_out <= accum(7 downto 0);
                data_out <= data_in;
                
                report "PE(" & integer'image(x) & ", " & integer'image(y) & ") accum_out: " & to_hstring(std_logic_vector(unsigned(accum_in) + unsigned(data_in) * unsigned(weight))) & " data_in: " & to_hstring(data_in);
            end if;
        end if;
    end process;
    
end architecture;