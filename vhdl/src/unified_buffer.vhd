-- Unified Buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity unified_buffer is
    generic (
        WIDTH : natural;
        DEPTH : natural
    );
    port (
        clk : in std_logic;
        
        master_enable : in std_logic;
        master_write_address : in natural range 0 to (DEPTH - 1);
        master_write_enable : in std_logic;
        master_write_data : in data_array;
        master_read_address : in natural range 0 to (DEPTH - 1);
        master_read_data : out data_array;

        port_0_enable : in std_logic;
        port_0_write_address : in natural range 0 to (DEPTH - 1);
        port_0_write_enable : in std_logic;
        port_0_write_data : in data_array;

        port_1_enable : in std_logic;
        port_1_read_address : in natural range 0 to (DEPTH - 1);
        port_1_read_data : out data_array
    );
end entity unified_buffer;

architecture behave of unified_buffer is

    type RAM_t is array(0 to (DEPTH - 1)) of std_logic_vector(((DATA_WIDTH * WIDTH) - 1) downto 0);
    shared variable RAM : RAM_t;

    --attribute ram_style : string;
    --attribute ram_style of RAM : variable is "block";

    signal enable_0: std_logic;
    signal enable_1 : std_logic;

    signal address_0 : natural range 0 to (DEPTH - 1);
    signal address_1 : natural range 0 to (DEPTH - 1);

    signal master_read_data_reg : data_array;
    signal port_1_read_data_reg : data_array;

begin

    process (all)
    begin
        if master_enable = '1' then
            enable_0 <= '1';
            enable_1 <= '1';
            address_0 <= master_write_address;
            address_1 <= master_read_address;
        else
            enable_0 <= port_0_enable;
            enable_1 <= port_1_enable;
            address_0 <= port_0_write_address;
            address_1 <= port_1_read_address;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if enable_0 = '1' then
                if port_0_write_enable = '1' then
                    for i in 0 to (WIDTH - 1) loop
                        RAM(address_0)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH) := port_0_write_data(i);
                    end loop;
                end if;
                for i in 0 to (WIDTH - 1) loop
                    master_read_data_reg(i) <= RAM(address_1)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH);
                end loop;
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            master_read_data <= master_read_data_reg;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            if enable_1 = '1' then
                if master_write_enable = '1' then
                    for i in 0 to (WIDTH - 1) loop
                        RAM(address_0)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH) := master_write_data(i);
                    end loop;
                end if;
                for i in 0 to (WIDTH - 1) loop
                    port_1_read_data_reg(i) <= RAM(address_1)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH);
                end loop;
            end if;
        end if;
    end process;

    process (clk)
    begin
        if rising_edge(clk) then
            port_1_read_data <= port_1_read_data_reg;
        end if;
    end process;

end architecture;