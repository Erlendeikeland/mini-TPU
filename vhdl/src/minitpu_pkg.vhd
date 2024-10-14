library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library std;
use std.textio.all;

package minitpu_pkg is

    -- SYSTOLIC ARRAY --
    constant SIZE : natural := 8;

    -- Data interface
    constant DATA_WIDTH : natural := 8;
    type data_array is array(0 to (SIZE - 1)) of std_logic_vector((DATA_WIDTH - 1) downto 0);

    -- Weight interface
    constant WEIGHT_WIDTH : natural := 8;
    type weight_array is array(0 to (SIZE - 1)) of std_logic_vector((WEIGHT_WIDTH - 1) downto 0);
    





    constant MAX_ACCUM_WIDTH : natural := 19;

    type output_vector_t is array(natural range <>) of std_logic_vector((MAX_ACCUM_WIDTH - 1) downto 0);

    function get_accum_width(row : natural) return natural;







    -- DEBUGGING --
    procedure report_line(inp : string);

end package;

package body minitpu_pkg is

    function get_accum_width(row : natural) return natural is
        variable acc_value : natural := 0;
        variable sum_value : natural := 0;
    begin
        for i in 0 to row loop
            acc_value := (2**DATA_WIDTH - 1) * (2**WEIGHT_WIDTH - 1);
            sum_value := sum_value + acc_value;
        end loop;
        return integer(ceil(log2(real(sum_value))));
    end function;







    -- DEBUGGING --
    procedure report_line(inp : string) is
        variable LineBuffer : LINE;
    begin
        write(LineBuffer, string'(inp));
        writeline(output, LineBuffer);
    end procedure;
    
end package body;