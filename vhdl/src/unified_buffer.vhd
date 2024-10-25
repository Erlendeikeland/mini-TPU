-- Unified Buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity unified_buffer is
    generic (
        WIDTH : integer;
        DEPTH : integer
    );
    port (
        clk : in std_logic;
        
        -- Master (Read/Write)
        master_enable : in std_logic;
        master_write_address : in natural range 0 to (DEPTH - 1);
        master_write_enable : in std_logic;
        master_write_data : in data_array;
        master_read_address : in natural range 0 to (DEPTH - 1);
        master_read_data : out data_array;

        -- Port 0 (Write)
        port_0_enable : in std_logic;
        port_0_write_address : in natural range 0 to (DEPTH - 1);
        port_0_write_enable : in std_logic;
        port_0_write_data : in data_array;

        -- Port 1 (Read)
        port_1_enable : in std_logic;
        port_1_read_address : in natural range 0 to (DEPTH - 1);
        port_1_read_data : out data_array
    );
end entity unified_buffer;

architecture behave of unified_buffer is

    type RAM_t is array(0 to (DEPTH - 1)) of std_logic_vector((DATA_WIDTH * WIDTH) - 1 downto 0);
    shared variable RAM : RAM_t;

    signal enable_0: std_logic;
    signal enable_1 : std_logic;

begin

    enable_0 <= '0' when master_enable = '1' else port_0_enable;
    enable_1 <= '0' when master_enable = '1' else port_1_enable;

    -- Master (Read/Write)
    process (clk)
    begin
        if rising_edge(clk) then
            if master_enable = '1' then
                if master_write_enable = '1' then
                    for i in 0 to (WIDTH - 1) loop
                        RAM(master_write_address)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH) := master_write_data(i);
                    end loop;
                end if;
                for i in 0 to (WIDTH - 1) loop
                    master_read_data(i) <= RAM(master_read_address)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH);
                end loop;
            end if;
        end if;
    end process;

    -- Port 0 (Write)
    process (clk)
    begin
        if rising_edge(clk) then
            if enable_0 = '1' then
                if port_0_write_enable = '1' then
                    for i in 0 to (WIDTH - 1) loop
                        ram(port_0_write_address)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH) := port_0_write_data(i);
                    end loop;
                end if;            
            end if;
        end if;
    end process;
    
    -- Port 1 (Read)
    process (clk)
    begin
        if rising_edge(clk) then
            if enable_1 = '1' then
                for i in 0 to (WIDTH - 1) loop
                    port_1_read_data(i) <= ram(port_1_read_address)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH);
                end loop;    
            end if;
        end if;
    end process;

end architecture;