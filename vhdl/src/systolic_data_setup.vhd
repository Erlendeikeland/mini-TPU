-- Systolic Data Setup

library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity systolic_data_setup is
    generic (
        MATRIX_WIDTH : natural;
        PIPELINE_STAGES : natural
    );
    port (
        clk : in std_logic;
        data_in : in data_array;
        data_out : out data_array
    );
end entity systolic_data_setup;

architecture behave of systolic_data_setup is

    type data_array_2d is array (1 to (MATRIX_WIDTH - 1), 1 to (MATRIX_WIDTH - 1)) of std_logic_vector((DATA_WIDTH - 1) downto 0);
    signal data_reg : data_array_2d;

    type pipeline_array_t is array(0 to (PIPELINE_STAGES - 1)) of data_array;
    signal data_out_reg : pipeline_array_t;

    signal temp_data_out : data_array;

begin

    process(clk)
        variable temp_data : data_array_2d;
    begin
        if rising_edge(clk) then
            for i in 1 to (MATRIX_WIDTH - 1) loop
                for j in 1 to (MATRIX_WIDTH - 1) loop
                    if i = 1 then
                        temp_data(i, j) := data_in(j);
                    else
                        temp_data(i, j) := data_reg((i - 1), j);
                    end if;
                end loop;
            end loop;
        
            data_reg <= temp_data;
        end if;
    end process;

    process (all)
    begin
        temp_data_out(0) <= data_in(0);
        for i in 1 to (MATRIX_WIDTH - 1) loop
            temp_data_out(i) <= data_reg(i, i);
        end loop;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            data_out_reg(0) <= temp_data_out;
            for i in 1 to (PIPELINE_STAGES - 1) loop
                data_out_reg(i) <= data_out_reg((i - 1));
            end loop;
        end if;
    end process;

    data_out <= data_out_reg((PIPELINE_STAGES - 1));

end architecture;