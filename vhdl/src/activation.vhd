library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity activation is
    generic (
        WIDTH : natural
    );
    port (
        clk : in std_logic;

        data_in : in output_array;
        data_out : out data_array
    );
end entity activation;

architecture rtl of activation is

begin

    output_gen : for i in 0 to (WIDTH - 1) generate
        data_out(i) <= data_in(i)((DATA_WIDTH - 1) downto 0);
    end generate;

end architecture;