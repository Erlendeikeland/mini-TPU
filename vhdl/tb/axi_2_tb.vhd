library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

use work.minitpu_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;
use uvvm_util.axilite_bfm_pkg.all;

entity axi_2_tb is
end entity axi_2_tb;

architecture behave of axi_2_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';
    signal reset : std_logic := '1';

    constant C_S_AXI_DATA_WIDTH : integer := 32;
    constant C_S_AXI_ADDR_WIDTH : integer := 20;

    constant BLOCKS : natural := (DATA_WIDTH * SIZE) / C_S_AXI_DATA_WIDTH;

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
            assert to_integer(address(1 downto 0)) mod 4 = 0 report "Unaligned write: offset must be multiple of 4." severity failure;
            axilite_write(address, data, msg, clk, axilite_if);
        end;

        variable read_address : unsigned((C_S_AXI_ADDR_WIDTH - 1) downto 0);
        variable read_data : std_logic_vector((C_S_AXI_DATA_WIDTH - 1) downto 0);

        procedure axilite_read (
            constant address : in unsigned;
            variable read_data : out std_logic_vector;
            constant msg : in string
        ) is
        begin
            assert to_integer(address(1 downto 0)) mod 4 = 0 report "Unaligned write: offset must be multiple of 4." severity failure;
            axilite_read(address, read_data, msg, clk, axilite_if);
        end;

    begin
        wait for CLK_PERIOD * 5;

        axilite_bfm_config.clock_period <= CLK_PERIOD;
        axilite_if <= init_axilite_if_signals(C_S_AXI_ADDR_WIDTH, C_S_AXI_DATA_WIDTH);

        wait for CLK_PERIOD * 5;

        write_data := 32x"22222222";
        write_address := to_unsigned(0, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(0, 2) & "00";
        axilite_write(write_address, write_data, "Write");

        write_data := 32x"22222222";
        write_address := to_unsigned(0, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(1, 2) & "00";
        axilite_write(write_address, write_data, "Write");

        write_data := 32x"33333333";
        write_address := to_unsigned(4, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(0, 2) & "00";
        axilite_write(write_address, write_data, "Write");

        write_data := 32x"55555555";
        write_address := to_unsigned(1, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(1, 2) & "00";
        axilite_write(write_address, write_data, "Write");

        write_data := 32x"55555555";
        write_address := to_unsigned(1, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(0, 2) & "00";
        axilite_write(write_address, write_data, "Write");
        
        wait for CLK_PERIOD * 20;

        read_address := to_unsigned(0, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(0, 2) & "00";
        axilite_read(read_address, read_data, "Read");

        read_address := to_unsigned(0, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(1, 2) & "00";
        axilite_read(read_address, read_data, "Read");

        read_address := to_unsigned(1, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(0, 2) & "00";
        axilite_read(read_address, read_data, "Read");

        read_address := to_unsigned(1, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(1, 2) & "00";
        axilite_read(read_address, read_data, "Read");

        stop;
    end process;

end architecture;