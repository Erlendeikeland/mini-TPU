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
    constant C_S_AXI_ADDR_WIDTH : integer := 16;

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

    type array_t is array(0 to (SIZE - 1)) of data_array;
    
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

        procedure generate_expected_result (
            constant a : in array_t;
            constant b : in array_t;
            variable result : out array_t
        ) is
            variable temp : std_logic_vector(((DATA_WIDTH * 2) - 1) downto 0) := (others => '0');
        begin
            for i in 0 to (SIZE - 1) loop
                for j in 0 to (SIZE - 1) loop
                    for k in 0 to (SIZE - 1) loop
                        temp := std_logic_vector(unsigned(temp) + unsigned(a(i)(k)) * unsigned(b(k)(j)));
                    end loop;
                    result(i)(j) := temp((DATA_WIDTH - 1) downto 0);
                    temp := (others => '0');
                end loop;
            end loop;
        end;

        procedure get_random_array (
            variable matrix : out array_t
        ) is
        begin
            for i in 0 to (SIZE - 1) loop
                for j in 0 to (SIZE - 1) loop
                    matrix(i)(j) := std_logic_vector(to_unsigned(integer(random(0, 4)), DATA_WIDTH));
                end loop;
            end loop;
        end;

        variable array_a : array_t := (others => (others => (others => '0')));
        variable array_b : array_t := (others => (others => (others => '0')));
        
        variable weight_a : array_t := (others => (others => (others => '0')));
        variable weight_b : array_t := (others => (others => (others => '0')));

        variable result_array_0 : array_t := (others => (others => (others => '0')));
        variable result_array_1 : array_t := (others => (others => (others => '0')));
        variable result_array_2 : array_t := (others => (others => (others => '0')));

        variable expected_result_0 : array_t := (others => (others => (others => '0')));
        variable expected_result_1 : array_t := (others => (others => (others => '0')));
        variable expected_result_2 : array_t := (others => (others => (others => '0')));

    begin
        wait for CLK_PERIOD * 5;

        axilite_bfm_config.clock_period <= CLK_PERIOD;
        axilite_if <= init_axilite_if_signals(C_S_AXI_ADDR_WIDTH, C_S_AXI_DATA_WIDTH);

        get_random_array(array_a);
        get_random_array(array_b);

        get_random_array(weight_a);
        get_random_array(weight_b);

        generate_expected_result(array_a, weight_a, expected_result_0);
        generate_expected_result(array_a, weight_b, expected_result_1);
        generate_expected_result(array_b, weight_b, expected_result_2);

        wait for CLK_PERIOD * 5;

        -- Write unified buffer data
        for i in 0 to (SIZE - 1) loop
            for j in 0 to (BLOCKS - 1) loop
                for k in 0 to (4 - 1) loop
                    write_data(8 * k + 7 downto 8 * k) := array_a(i)((j * 4) + k);
                end loop;
                write_address := to_unsigned(i, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(j, 2) & "00";
                axilite_write(write_address, write_data, "Write unified, address: " & integer'image(to_integer(to_unsigned(i, C_S_AXI_ADDR_WIDTH - 2))) & ", offset: " & integer'image(j));
            end loop;
        end loop;

        -- Write unified buffer data
        for i in 0 to (SIZE - 1) loop
            for j in 0 to (BLOCKS - 1) loop
                for k in 0 to (4 - 1) loop
                    write_data(8 * k + 7 downto 8 * k) := array_b(i)((j * 4) + k);
                end loop;
                write_address := to_unsigned(i + SIZE, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(j, 2) & "00";
                axilite_write(write_address, write_data, "Write unified, address: " & integer'image(to_integer(to_unsigned(i, C_S_AXI_ADDR_WIDTH - 2))) & ", offset: " & integer'image(j));
            end loop;
        end loop;

        wait for CLK_PERIOD * 5;

        -- Write weight data
        for i in 0 to (SIZE - 1) loop
            for j in 0 to (BLOCKS - 1) loop
                for k in 0 to (4 - 1) loop
                    write_data(8 * k + 7 downto 8 * k) := weight_a(i)((j * 4) + k);
                end loop;
                write_address := to_unsigned(i, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(1, 2) & to_unsigned(j, 2) & "00";
                axilite_write(write_address, write_data, "Write weight, address: " & integer'image(to_integer(to_unsigned(i, C_S_AXI_ADDR_WIDTH - 2))) & ", offset: " & integer'image(j));
            end loop;
        end loop;

        -- Write weight data
        for i in 0 to (SIZE - 1) loop
            for j in 0 to (BLOCKS - 1) loop
                for k in 0 to (4 - 1) loop
                    write_data(8 * k + 7 downto 8 * k) := weight_b(i)((j * 4) + k);
                end loop;
                write_address := to_unsigned(i + SIZE, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(1, 2) & to_unsigned(j, 2) & "00";
                axilite_write(write_address, write_data, "Write weight, address: " & integer'image(to_integer(to_unsigned(i, C_S_AXI_ADDR_WIDTH - 2))) & ", offset: " & integer'image(j));
            end loop;
        end loop;

        -- Load weights
        write_data := std_logic_vector(to_unsigned(0, 30)) & std_logic_vector(to_unsigned(2, 2));
        write_address := to_unsigned(0, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(2, 2) & to_unsigned(0, 4);
        axilite_write(write_address, write_data, "write instruction");

        -- Matrix multiply
        write_data := std_logic_vector(to_unsigned(0, 15)) & std_logic_vector(to_unsigned(SIZE * 2, 15)) & std_logic_vector(to_unsigned(1, 2));
        write_address := to_unsigned(0, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(2, 2) & to_unsigned(0, 4);
        axilite_write(write_address, write_data, "write instruction");

        -- Load weights
        write_data := std_logic_vector(to_unsigned(SIZE, 30)) & std_logic_vector(to_unsigned(2, 2));
        write_address := to_unsigned(0, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(2, 2) & to_unsigned(0, 4);
        axilite_write(write_address, write_data, "write instruction");

        -- Matrix multiply
        write_data := std_logic_vector(to_unsigned(0, 15)) & std_logic_vector(to_unsigned(SIZE * 3, 15)) & std_logic_vector(to_unsigned(1, 2));
        write_address := to_unsigned(0, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(2, 2) & to_unsigned(0, 4);
        axilite_write(write_address, write_data, "write instruction");

        -- Matrix multiply
        write_data := std_logic_vector(to_unsigned(SIZE, 15)) & std_logic_vector(to_unsigned(SIZE * 4, 15)) & std_logic_vector(to_unsigned(1, 2));
        write_address := to_unsigned(0, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(2, 2) & to_unsigned(0, 4);
        axilite_write(write_address, write_data, "write instruction");

        wait for CLK_PERIOD * 500;

        -- Read result
        for i in 0 to (SIZE - 1) loop
            for j in 0 to (BLOCKS - 1) loop
                read_address := to_unsigned(i + SIZE * 2, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(j, 2) & "00";
                axilite_read(read_address, read_data, "Read unified, address: " & integer'image(to_integer(to_unsigned(i, C_S_AXI_ADDR_WIDTH - 2))) & ", offset: " & integer'image(j));

                for k in 0 to (4 - 1) loop
                    result_array_0(i)((j * 4) + k) := read_data(8 * k + 7 downto 8 * k);
                end loop;
            end loop;
        end loop;

        -- Read result
        for i in 0 to (SIZE - 1) loop
            for j in 0 to (BLOCKS - 1) loop
                read_address := to_unsigned(i + SIZE * 3, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(j, 2) & "00";
                axilite_read(read_address, read_data, "Read unified, address: " & integer'image(to_integer(to_unsigned(i, C_S_AXI_ADDR_WIDTH - 2))) & ", offset: " & integer'image(j));

                for k in 0 to (4 - 1) loop
                    result_array_1(i)((j * 4) + k) := read_data(8 * k + 7 downto 8 * k);
                end loop;
            end loop;
        end loop;

        -- Read accumulator data
        for i in 0 to (SIZE - 1) loop
            for j in 0 to (BLOCKS - 1) loop
                read_address := to_unsigned(i + SIZE * 4, C_S_AXI_ADDR_WIDTH - 6) & to_unsigned(0, 2) & to_unsigned(j, 2) & "00";
                axilite_read(read_address, read_data, "Read unified, address: " & integer'image(to_integer(to_unsigned(i, C_S_AXI_ADDR_WIDTH - 2))) & ", offset: " & integer'image(j));

                for k in 0 to (4 - 1) loop
                    result_array_2(i)((j * 4) + k) := read_data(8 * k + 7 downto 8 * k);
                end loop;
            end loop;
        end loop;
        
        wait for CLK_PERIOD * 5;

        for i in 0 to (SIZE - 1) loop
            for j in 0 to (SIZE - 1) loop
                assert result_array_0(i)(j) = expected_result_0(i)(j) report "Mismatch in result 0" severity failure;
                assert result_array_1(i)(j) = expected_result_1(i)(j) report "Mismatch in result 1" severity failure;
                assert result_array_2(i)(j) = expected_result_2(i)(j) report "Mismatch in result 2" severity failure;
            end loop;
        end loop;

        report_line("");

        for i in 0 to SIZE - 1 loop
            report_array(result_array_0(i));
        end loop;

        report_line("");
        
        for i in 0 to SIZE - 1 loop
            report_array(result_array_1(i));
        end loop;
            
        report_line("");

        for i in 0 to SIZE - 1 loop
            report_array(result_array_2(i));
        end loop;
        
        wait for CLK_PERIOD * 20;

        stop;
    end process;

end architecture;