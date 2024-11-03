-- Instruction FIFO

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

        write_enable : in std_logic;
        write_data : in op_t;
        full : out std_logic;
        
        read_enable : in std_logic;
        read_data : out op_t;
        empty : out std_logic
    );
end entity fifo;

architecture behave of fifo is

    type fifo_t is array(0 to (DEPTH - 1)) of op_t;
    signal fifo : fifo_t;

    signal head : natural range 0 to DEPTH;
    signal tail : natural range 0 to DEPTH;

    signal looped : std_logic;

    signal temp_full : std_logic;
    signal temp_empty : std_logic;

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                head <= 0;
                tail <= 0;
                looped <= '0';
            else
                if write_enable = '1' and temp_full = '0' then
                    fifo(head) <= write_data;
                    head <= head + 1;
                    if head = DEPTH - 1 then
                        head <= 0;
                        looped <= not looped;
                    end if;
                end if;

                if read_enable = '1' and temp_empty = '0' then
                    tail <= tail + 1;
                    if tail = DEPTH - 1 then
                        tail <= 0;
                        looped <= not looped;
                    end if;
                end if;
            end if;
        end if;
    end process;

    read_data <= fifo(tail);

    temp_full <= '1' when looped = '1' and head = tail else '0';
    temp_empty <= '1' when looped = '0' and head = tail else '0';

    full <= temp_full;
    empty <= temp_empty;

end architecture;