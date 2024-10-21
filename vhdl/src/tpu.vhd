library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity tpu is
    port (
        clk : in std_logic;
        reset : in std_logic
    );
end entity tpu;

architecture behave of tpu is

    signal sysarr_enable : std_logic;
    signal sysarr_data_out : output_vector_t;
    signal sysarr_weight_addr : natural range 0 to (SIZE - 1);
    signal sysarr_load_weights : std_logic;

    constant WEIGHT_BUFFER_WIDTH : natural := 8;
    constant WEIGHT_BUFFER_DEPTH : natural := 8;
    
    signal weight_buffer_wdata : weight_array;
    signal weight_buffer_waddr : natural range 0 to (WEIGHT_BUFFER_DEPTH - 1);
    signal weight_buffer_wen : std_logic;
    signal weight_buffer_rdata : weight_array;
    signal weight_buffer_raddr : natural range 0 to (WEIGHT_BUFFER_DEPTH - 1);
    signal weight_buffer_ren : std_logic;

    constant DATA_BUFFER_WIDTH : natural := 8;
    constant DATA_BUFFER_DEPTH : natural := 8;

    signal data_buffer_wdata : data_array;
    signal data_buffer_waddr : natural range 0 to (DATA_BUFFER_DEPTH - 1);
    signal data_buffer_wen : std_logic;
    signal data_buffer_rdata : data_array;
    signal data_buffer_raddr : natural range 0 to (DATA_BUFFER_DEPTH - 1);
    signal data_buffer_ren : std_logic;

begin

    systolic_array_inst: entity work.systolic_array
        port map(
            clk => clk,
            enable => ,
            data_in => data_buffer_rdata,
            data_out => ,
            weights => weight_buffer_rdata,
            weight_addr => ,
            load_weights => 
        );

    weight_buffer_inst: entity work.weight_buffer
        generic map(
            WIDTH => WEIGHT_BUFFER_WIDTH,
            DEPTH => WEIGHT_BUFFER_DEPTH
        )
        port map(
            clk => clk,
            reset => reset,
            write_data => ,
            write_addr => ,
            write_en => ,
            read_data => weight_buffer_rdata,
            read_addr => ,
            read_en => 
        );

    data_buffer_inst: entity work.data_buffer
        generic map(
            WIDTH => DATA_BUFFER_WIDTH,
            DEPTH => DATA_BUFFER_DEPTH
        )
        port map(
            clk => clk,
            reset => reset,
            write_data => ,
            write_addr => ,
            write_en => ,
            read_data => data_buffer_rdata,
            read_addr => ,
            read_en => 
        );

end architecture;