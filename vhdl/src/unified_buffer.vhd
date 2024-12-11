-- Unified Buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity unified_buffer is
    generic (
        WIDTH : natural;
        DEPTH : natural;
        PIPELINE_STAGES : natural range 1 to integer'high
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

    signal enable_0: std_logic;
    signal enable_1 : std_logic;

    signal address_0 : natural range 0 to (DEPTH - 1);
    signal address_1 : natural range 0 to (DEPTH - 1);

    signal master_temp_data : data_array;
    signal port_1_temp_data : data_array;
    
    type pipeline_t is array(0 to (PIPELINE_STAGES - 2)) of data_array;
    signal master_pipeline : pipeline_t;
    signal port_1_pipeline : pipeline_t;

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
                    master_temp_data(i) <= RAM(address_1)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH);
                end loop;
            end if;
        end if;
    end process;

    pipeline_gen : if PIPELINE_STAGES = 1 generate
        master_read_data <= master_temp_data;
    else generate
        process (clk)
        begin
            if rising_edge(clk) then
                master_pipeline(0) <= master_temp_data;
                for i in 1 to (PIPELINE_STAGES - 2) loop
                    master_pipeline(i) <= master_pipeline(i - 1);
                end loop;
            end if;
        end process;
        
        master_read_data <= master_pipeline(PIPELINE_STAGES - 2);
    end generate;

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
                    port_1_temp_data(i) <= RAM(address_1)(i * DATA_WIDTH + (DATA_WIDTH - 1) downto i * DATA_WIDTH);
                end loop;
            end if;
        end if;
    end process;

    pipeline_gen_1 : if PIPELINE_STAGES = 1 generate
        port_1_read_data <= port_1_temp_data;
    else generate
        process (clk)
        begin
            if rising_edge(clk) then
                port_1_pipeline(0) <= port_1_temp_data;
                for i in 1 to (PIPELINE_STAGES - 2) loop
                    port_1_pipeline(i) <= port_1_pipeline(i - 1);
                end loop;
            end if;
        end process;
        
        port_1_read_data <= port_1_pipeline(PIPELINE_STAGES - 2);
    end generate;

end architecture;