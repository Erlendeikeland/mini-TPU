-- Instruction FIFO
-- OPs are written to FIFO

library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity fifo is
    generic (
        DEPTH : integer := 16
    );
    port (
        clk : in std_logic;
        reset : in std_logic;

        -- Write
        write_en : in std_logic;
        write_data : in op_t;
        full : out std_logic;
        
        -- Read
        read_en : in std_logic;
        read_data : out op_t;
        empty : out std_logic
    );
end entity fifo;

architecture rtl of fifo is

    type fifo_t is array(0 to (DEPTH - 1)) of op_t;
    signal fifo : fifo_t;

    signal write_index : integer range 0 to (DEPTH - 1);
    signal read_index : integer range 0 to (DEPTH - 1);
    signal count : integer range 0 to DEPTH;

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                write_index <= 0;
                read_index <= 0;
                count <= 0;
            else
                if write_en = '1' then
                    if count < DEPTH then
                        fifo(write_index) <= write_data;
                        write_index <= write_index + 1;
                        count <= count + 1;
                    end if;
                end if;

                if read_en = '1' then
                    if count > 0 then
                        read_data <= fifo(read_index);
                        read_index <= read_index + 1;
                        count <= count - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    full <= '1' when count = DEPTH else '0';
    empty <= '1' when count = 0 else '0';

end architecture;