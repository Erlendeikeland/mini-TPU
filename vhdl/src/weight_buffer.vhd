-- Buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity weight_buffer is
    generic (
        WIDTH : natural;
        DEPTH : natural;
        PIPELINE_STAGES : natural
    );
    port (
        clk : in std_logic;
        
        port_0_enable : in std_logic;
        port_0_write_data : in weight_array;
        port_0_write_address : in natural range 0 to (DEPTH - 1);
        port_0_write_enable : in std_logic;

        port_1_enable : in std_logic;
        port_1_read_data : out weight_array;
        port_1_read_address : in natural range 0 to (DEPTH - 1)
    );
end entity weight_buffer;

architecture behave of weight_buffer is

    type RAM_t is array(0 to (DEPTH - 1)) of std_logic_vector(((DATA_WIDTH * WIDTH) - 1) downto 0);
    shared variable RAM : RAM_t;

    --attribute ram_style : string;
    --attribute ram_style of RAM : variable is "block";
    
    type pipeline_array_t is array(0 to (PIPELINE_STAGES - 1)) of weight_array;
    signal port_1_read_data_reg : pipeline_array_t;
    
begin

    process (clk)
    begin
        if rising_edge(clk) then
            if port_0_enable = '1' then
                if port_0_write_enable = '1' then
                    for i in 0 to (WIDTH - 1) loop
                        RAM(port_0_write_address)((i * DATA_WIDTH + (DATA_WIDTH - 1)) downto (i * DATA_WIDTH)) := port_0_write_data(i);
                    end loop;
                end if;
            end if;
        end if;
    end process;
    
    process (clk)
    begin
        if rising_edge(clk) then
            if port_1_enable = '1' then
                for i in 0 to (WIDTH - 1) loop
                    port_1_read_data_reg(0)(i) <= RAM(port_1_read_address)((i * DATA_WIDTH + (DATA_WIDTH - 1)) downto (i * DATA_WIDTH));
                end loop;
            end if;

            for i in 1 to (PIPELINE_STAGES - 1) loop
                port_1_read_data_reg(i) <= port_1_read_data_reg(i - 1);
            end loop;
        end if;
    end process;

    port_1_read_data <= port_1_read_data_reg(PIPELINE_STAGES - 1);

end architecture;