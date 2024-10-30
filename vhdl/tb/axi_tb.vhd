library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.minitpu_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;
use uvvm_util.axistream_bfm_pkg.all;

entity axi_tb is
end entity axi_tb;

architecture behave of axi_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';
    signal reset : std_logic := '1';

    constant C_S_AXIS_TDATA_WIDTH : integer := 32;

    signal axistream_bfm_config : t_axistream_bfm_config := C_AXISTREAM_BFM_CONFIG_DEFAULT;

    signal axistream_if : t_axistream_if(
        tdata(C_S_AXIS_TDATA_WIDTH - 1 downto 0),
        tkeep(C_S_AXIS_TDATA_WIDTH / 8 - 1 downto 0),
        tuser(0 downto 0),
        tstrb(C_S_AXIS_TDATA_WIDTH / 8 - 1 downto 0),
        tid(0 downto 0),
        tdest(0 downto 0)
    );

begin

    S00_AXIS_inst: entity work.S00_AXIS
        generic map(
            C_S_AXIS_TDATA_WIDTH => C_S_AXIS_TDATA_WIDTH
        )
        port map(
            S_AXIS_ACLK => clk,
            S_AXIS_ARESETN => reset,
            S_AXIS_TREADY => axistream_if.tready,
            S_AXIS_TDATA => axistream_if.tdata,
            S_AXIS_TSTRB => axistream_if.tstrb,
            S_AXIS_TLAST => axistream_if.tlast,
            S_AXIS_TVALID => axistream_if.tvalid,
            slave_valid => open,
            slave_ready => '0',
            slave_data => open
        );
    
    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        wait for CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;
        reset <= '1';
        wait;
    end process;

    process
    
        variable v_byte_array : t_byte_array(0 to 7) := (others => (others => '0'));

    begin
        wait for CLK_PERIOD * 5;

        axistream_bfm_config.clock_period <= CLK_PERIOD;

        axistream_if <= init_axistream_if_signals(
            is_master  => true,
            data_width => axistream_if.tdata'length,
            user_width => axistream_if.tuser'length,
            id_width => axistream_if.tid'length,
            dest_width => axistream_if.tdest'length,
            config => axistream_bfm_config
        );

        wait for CLK_PERIOD * 5;

        v_byte_array(0) := x"48";
        v_byte_array(1) := x"45";
        v_byte_array(2) := x"59";
        v_byte_array(3) := x"23";
        v_byte_array(4) := x"4A";
        v_byte_array(5) := x"4F";
        v_byte_array(6) := x"4E";
        v_byte_array(7) := x"41";

        axistream_transmit(v_byte_array, "0", clk, axistream_if);
        axistream_transmit(v_byte_array, "1", clk, axistream_if);
        axistream_transmit(v_byte_array, "2", clk, axistream_if);
        axistream_transmit(v_byte_array, "3", clk, axistream_if);
        axistream_transmit(v_byte_array, "4", clk, axistream_if);


        wait for CLK_PERIOD * 5;
        stop;
    end process;


end architecture;