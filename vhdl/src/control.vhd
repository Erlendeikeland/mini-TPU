library ieee;
use ieee.std_logic_1164.all;

use work.minitpu_pkg.all;

entity control is
    port (
        clk : in std_logic;
        reset : in std_logic;

        fifo_full : in std_logic;
        fifo_empty : in std_logic;
        fifo_read_enable : out std_logic;
        fifo_read_data : in op_t;

        weight_buffer_port_1_enable : out std_logic;
        weight_buffer_port_1_read_address : out natural;
        
        unified_buffer_port_0_enable : out std_logic;
        unified_buffer_port_0_write_address : out natural;
        unified_buffer_port_0_write_enable : out std_logic;
        unified_buffer_port_1_enable : out std_logic;
        unified_buffer_port_1_read_address : out natural;
        
        systolic_array_weight_address : out natural;
        systolic_array_weight_enable : out std_logic;
        
        accumulator_accumulate : out std_logic;
        accumulator_write_address : out natural;
        accumulator_write_enable : out std_logic;
        accumulator_read_address : out natural
    );
end entity control;

architecture behave of control is

    

begin



end architecture;