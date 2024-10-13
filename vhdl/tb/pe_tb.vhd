library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity pe_tb is
end entity pe_tb;

architecture behave of pe_tb is

    constant CLK_PERIOD: time := 10 ns;
    signal clk: std_logic := '1';

    constant ACCUM_IN_WIDTH0: integer := 16;
    constant ACCUM_OUT_WIDTH0: integer := 17;
    signal enable0: std_logic := '0';    
    signal data_in0: std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');
    signal data_out0: std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');
    signal accum_in0: std_logic_vector((ACCUM_IN_WIDTH0 - 1) downto 0) := (others => '0');
    signal accum_out0: std_logic_vector((ACCUM_OUT_WIDTH0 - 1) downto 0) := (others => '0');
    signal weight0: std_logic_vector((WEIGHT_WIDTH - 1) downto 0) := (others => '0');
    signal load_weight0: std_logic := '0';

    constant ACCUM_IN_WIDTH1: integer := 19;
    constant ACCUM_OUT_WIDTH1: integer := 19;
    signal enable1: std_logic := '0';
    signal data_in1: std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');
    signal data_out1: std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');
    signal accum_in1: std_logic_vector((ACCUM_IN_WIDTH1 - 1) downto 0) := (others => '0');
    signal accum_out1: std_logic_vector((ACCUM_OUT_WIDTH1 - 1) downto 0) := (others => '0');
    signal weight1: std_logic_vector((WEIGHT_WIDTH - 1) downto 0) := (others => '0');
    signal load_weight1: std_logic := '0';

    constant ACCUM_IN_WIDTH2: integer := 0;
    constant ACCUM_OUT_WIDTH2: integer := 16;
    signal enable2: std_logic := '0';
    signal data_in2: std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');
    signal data_out2: std_logic_vector((DATA_WIDTH - 1) downto 0) := (others => '0');
    signal accum_in2: std_logic_vector((ACCUM_IN_WIDTH2 - 1) downto 0) := (others => '0');
    signal accum_out2: std_logic_vector((ACCUM_OUT_WIDTH2 - 1) downto 0) := (others => '0');
    signal weight2: std_logic_vector((WEIGHT_WIDTH - 1) downto 0) := (others => '0');
    signal load_weight2: std_logic := '0';

begin

    PE_inst0: entity work.PE
        generic map(
            ACCUM_IN_WIDTH => ACCUM_IN_WIDTH0,
            ACCUM_OUT_WIDTH => ACCUM_OUT_WIDTH0
        )
        port map(
            clk => clk,
            enable => enable0,
            data_in => data_in0,
            data_out => data_out0,
            accum_in => accum_in0,
            accum_out => accum_out0,
            weight => weight0,
            load_weight => load_weight0
        );

    PE_inst1: entity work.PE
        generic map(
            ACCUM_IN_WIDTH => ACCUM_IN_WIDTH1,
            ACCUM_OUT_WIDTH => ACCUM_OUT_WIDTH1
        )
        port map(
            clk => clk,
            enable => enable1,
            data_in => data_in1,
            data_out => data_out1,
            accum_in => accum_in1,
            accum_out => accum_out1,
            weight => weight1,
            load_weight => load_weight1
        );

    PE_inst2: entity work.PE
        generic map(
            ACCUM_IN_WIDTH => ACCUM_IN_WIDTH2,
            ACCUM_OUT_WIDTH => ACCUM_OUT_WIDTH2
        )
        port map(
            clk => clk,
            enable => enable2,
            data_in => data_in2,
            data_out => data_out2,
            accum_in => accum_in2,
            accum_out => accum_out2,
            weight => weight2,
            load_weight => load_weight2
        );

    process
    begin
        wait for CLK_PERIOD / 2;
        clk <= not clk;
    end process;

    process
        variable result : integer;
    begin
        wait for CLK_PERIOD * 2;

        for i in 0 to 10 loop
            for j in 0 to 10 loop
                for k in 0 to 10 loop
                    data_in0 <= std_logic_vector(to_unsigned(i, DATA_WIDTH));
                    weight0 <= std_logic_vector(to_unsigned(j, WEIGHT_WIDTH));
                    accum_in0 <= std_logic_vector(to_unsigned(k, ACCUM_IN_WIDTH0));

                    load_weight0 <= '1';
                    wait for CLK_PERIOD;
                    load_weight0 <= '0';

                    wait for CLK_PERIOD;
                    enable0 <= '1';
                    wait for CLK_PERIOD;
                    enable0 <= '0';

                    result := k + i * j;
                    assert unsigned(accum_out0) = result report "Expected " & integer'image(result) & " but got " & integer'image(to_integer(unsigned(accum_out0)));
                    assert data_out0 = data_in0;
                end loop;
            end loop;
        end loop;

        wait for CLK_PERIOD * 2;

        for i in 245 to 255 loop
            for j in 245 to 255 loop
                for k in 65015 to 65025 loop
                    data_in0 <= std_logic_vector(to_unsigned(i, DATA_WIDTH));
                    weight0 <= std_logic_vector(to_unsigned(j, WEIGHT_WIDTH));
                    accum_in0 <= std_logic_vector(to_unsigned(k, ACCUM_IN_WIDTH0));

                    load_weight0 <= '1';
                    wait for CLK_PERIOD;
                    load_weight0 <= '0';

                    wait for CLK_PERIOD;
                    enable0 <= '1';
                    wait for CLK_PERIOD;
                    enable0 <= '0';

                    result := k + i * j;
                    assert unsigned(accum_out0) = result report "Expected " & integer'image(result) & " but got " & integer'image(to_integer(unsigned(accum_out0)));
                    assert data_out0 = data_in0;
                end loop;
            end loop;
        end loop;

        wait;
    end process;

    process
        variable result : integer;
    begin
        wait for CLK_PERIOD * 2;

        for i in 0 to 10 loop
            for j in 0 to 10 loop
                for k in 0 to 10 loop
                    data_in1 <= std_logic_vector(to_unsigned(i, DATA_WIDTH));
                    weight1 <= std_logic_vector(to_unsigned(j, WEIGHT_WIDTH));
                    accum_in1 <= std_logic_vector(to_unsigned(k, ACCUM_IN_WIDTH1));

                    load_weight1 <= '1';
                    wait for CLK_PERIOD;
                    load_weight1 <= '0';

                    wait for CLK_PERIOD;
                    enable1 <= '1';
                    wait for CLK_PERIOD;
                    enable1 <= '0';

                    result := k + i * j;
                    assert unsigned(accum_out1) = result report "Expected " & integer'image(result) & " but got " & integer'image(to_integer(unsigned(accum_out1)));
                    assert data_out1 = data_in1;
                end loop;
            end loop;
        end loop;

        wait for CLK_PERIOD * 2;

        for i in 245 to 255 loop
            for j in 245 to 255 loop
                for k in 455165 to 455175 loop
                    data_in1 <= std_logic_vector(to_unsigned(i, DATA_WIDTH));
                    weight1 <= std_logic_vector(to_unsigned(j, WEIGHT_WIDTH));
                    accum_in1 <= std_logic_vector(to_unsigned(k, ACCUM_IN_WIDTH1));

                    load_weight1 <= '1';
                    wait for CLK_PERIOD;
                    load_weight1 <= '0';

                    wait for CLK_PERIOD;
                    enable1 <= '1';
                    wait for CLK_PERIOD;
                    enable1 <= '0';

                    result := k + i * j;
                    assert unsigned(accum_out1) = result report "Expected " & integer'image(result) & " but got " & integer'image(to_integer(unsigned(accum_out1)));
                    assert data_out1 = data_in1;
                end loop;
            end loop;
        end loop;

        wait;
    end process;

    process
        variable result : integer;
    begin
        wait for CLK_PERIOD * 2;

        for i in 0 to 10 loop
            for j in 0 to 10 loop
                for k in 0 to 0 loop
                    data_in2 <= std_logic_vector(to_unsigned(i, DATA_WIDTH));
                    weight2 <= std_logic_vector(to_unsigned(j, WEIGHT_WIDTH));
                    accum_in2 <= std_logic_vector(to_unsigned(k, ACCUM_IN_WIDTH2));

                    load_weight2 <= '1';
                    wait for CLK_PERIOD;
                    load_weight2 <= '0';

                    wait for CLK_PERIOD;
                    enable2 <= '1';
                    wait for CLK_PERIOD;
                    enable2 <= '0';

                    result := k + i * j;
                    assert unsigned(accum_out2) = result report "Expected " & integer'image(result) & " but got " & integer'image(to_integer(unsigned(accum_out2)));
                    assert data_out2 = data_in2;
                end loop;
            end loop;
        end loop;

        wait for CLK_PERIOD * 2;

        for i in 245 to 255 loop
            for j in 245 to 255 loop
                for k in 0 to 0 loop
                    data_in2 <= std_logic_vector(to_unsigned(i, DATA_WIDTH));
                    weight2 <= std_logic_vector(to_unsigned(j, WEIGHT_WIDTH));
                    accum_in2 <= std_logic_vector(to_unsigned(k, ACCUM_IN_WIDTH2));

                    load_weight2 <= '1';
                    wait for CLK_PERIOD;
                    load_weight2 <= '0';

                    wait for CLK_PERIOD;
                    enable2 <= '1';
                    wait for CLK_PERIOD;
                    enable2 <= '0';

                    result := k + i * j;
                    assert unsigned(accum_out2) = result report "Expected " & integer'image(result) & " but got " & integer'image(to_integer(unsigned(accum_out2)));
                    assert data_out2 = data_in2;
                end loop;
            end loop;
        end loop;

        wait;
    end process;

end architecture;