library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.minitpu_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;
use uvvm_util.axilite_bfm_pkg.all;

entity axi_tb is
end entity axi_tb;

architecture behave of axi_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';
    signal reset : std_logic := '1';

    constant C_S_AXI_DATA_WIDTH : integer := 32;
    constant C_S_AXI_ADDR_WIDTH : integer := 20;

    signal axilite_bfm_config : t_axilite_bfm_config := C_AXILITE_BFM_CONFIG_DEFAULT;

    signal axilite_if : t_axilite_if(
        write_address_channel(
            awaddr((C_S_AXI_ADDR_WIDTH - 1) downto 0)
        ),
        write_data_channel(
            wdata((C_S_AXI_DATA_WIDTH - 1) downto 0),
            wstrb(((C_S_AXI_DATA_WIDTH / 8) - 1) downto 0)
        ),
        read_address_channel(
            araddr((C_S_AXI_ADDR_WIDTH - 1) downto 0)
        ),
        read_data_channel(
            rdata((C_S_AXI_DATA_WIDTH - 1) downto 0)
        )
    );

    signal enable : std_logic := '0';

begin

    S00_AXI_inst: entity work.S00_AXI
        generic map(
            C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH
        )
        port map(
            S_AXI_ACLK => clk,
            S_AXI_ARESETN => reset,
            S_AXI_AWADDR => axilite_if.write_address_channel.awaddr,
            S_AXI_AWPROT => axilite_if.write_address_channel.awprot,
            S_AXI_AWVALID => axilite_if.write_address_channel.awvalid,
            S_AXI_AWREADY => axilite_if.write_address_channel.awready,
            S_AXI_WDATA => axilite_if.write_data_channel.wdata,
            S_AXI_WSTRB => axilite_if.write_data_channel.wstrb,
            S_AXI_WVALID => axilite_if.write_data_channel.wvalid,
            S_AXI_WREADY => axilite_if.write_data_channel.wready,
            S_AXI_BRESP => axilite_if.write_response_channel.bresp,
            S_AXI_BVALID => axilite_if.write_response_channel.bvalid,
            S_AXI_BREADY => axilite_if.write_response_channel.bready,
            S_AXI_ARADDR => axilite_if.read_address_channel.araddr,
            S_AXI_ARPROT => axilite_if.read_address_channel.arprot,
            S_AXI_ARVALID => axilite_if.read_address_channel.arvalid,
            S_AXI_ARREADY => axilite_if.read_address_channel.arready,
            S_AXI_RDATA => axilite_if.read_data_channel.rdata,
            S_AXI_RRESP => axilite_if.read_data_channel.rresp,
            S_AXI_RVALID => axilite_if.read_data_channel.rvalid,
            S_AXI_RREADY => axilite_if.read_data_channel.rready
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

        variable write_data : std_logic_vector((C_S_AXI_DATA_WIDTH - 1) downto 0);
        variable write_address : unsigned((C_S_AXI_ADDR_WIDTH - 1) downto 0);

        procedure axilite_write (
            constant address : in unsigned;
            constant data : in std_logic_vector;
            constant msg : in string
        ) is
        begin
            axilite_write(
                address,
                data,
                msg,
                clk,
                axilite_if
            );
        end;

        variable read_address : unsigned((C_S_AXI_ADDR_WIDTH - 1) downto 0);
        variable read_data : std_logic_vector((C_S_AXI_DATA_WIDTH - 1) downto 0);

        procedure axilite_read (
            constant address : in unsigned;
            variable read_data : out std_logic_vector;
            constant msg : in string
        ) is
        begin
            axilite_read(
                address,
                read_data,
                msg,
                clk,
                axilite_if
            );
        end;
        
    begin
        wait for CLK_PERIOD * 5;

        axilite_bfm_config.clock_period <= CLK_PERIOD;

        axilite_if <= init_axilite_if_signals(C_S_AXI_ADDR_WIDTH, C_S_AXI_DATA_WIDTH);

        wait for CLK_PERIOD * 5;

        for i in 0 to 7 loop
            write_data := std_logic_vector(to_unsigned(i, C_S_AXI_DATA_WIDTH));
            write_address := to_unsigned(i, C_S_AXI_ADDR_WIDTH);
            axilite_write(write_address, write_data, "Write data");
        end loop;

        wait for CLK_PERIOD * 5;

        for i in 0 to 7 loop
            read_address := to_unsigned(i, C_S_AXI_ADDR_WIDTH);
            axilite_read(read_address, read_data, "Read data");
        end loop;

        enable <= '1';
        wait for CLK_PERIOD * 0;
        enable <= '0';

        wait for CLK_PERIOD * 30;
        stop;
    end process;

end architecture;