library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.stop;

entity weight_buffer_tb is
end entity weight_buffer_tb;

use work.minitpu_pkg.all;

architecture behave of weight_buffer_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';

    signal reset : std_logic := '0';

    constant WIDTH : natural := 8;
    constant DEPTH : natural := 32;

    signal write_data : weight_array := (others => (others => '0'));
    signal write_addr : std_logic_vector((DEPTH - 1) downto 0);
    signal write_en : std_logic := '0';

    signal read_data : weight_array := (others => (others => '0'));
    signal read_addr : std_logic_vector((DEPTH - 1) downto 0);
    signal read_en : std_logic := '0';

begin

    weight_buffer_inst : entity work.weight_buffer
        generic map (
            WIDTH => WIDTH,
            DEPTH => DEPTH
        )
        port map (
            clk => clk,
            reset => reset,
            write_data => write_data,
            write_addr => write_addr,
            write_en => write_en,
            read_data => read_data,
            read_addr => read_addr,
            read_en => read_en
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        reset <= '1';
        wait for CLK_PERIOD;
        reset <= '0';
        wait;
    end process;

    process
    begin
        wait for CLK_PERIOD * 5;
        
        write_en <= '1';
        
        for i in 0 to (DEPTH - 1) loop
            for j in 0 to (WIDTH - 1) loop
                write_data(j) <= std_logic_vector(to_unsigned(i + j, write_data'length));
            end loop;
            write_addr <= std_logic_vector(to_unsigned(i, write_addr'length));
            wait for CLK_PERIOD;
        end loop;

        write_en <= '0';

        wait for CLK_PERIOD * 5;

        read_en <= '1';

        for i in 0 to (DEPTH - 1) loop
            read_addr <= std_logic_vector(to_unsigned(i, read_addr'length));
            wait for CLK_PERIOD;
        end loop;

        read_en <= '0';

        wait for CLK_PERIOD * 5;

        stop;
    end process;

    process
        variable errors : natural := 0;
    begin
        wait until read_en = '1';
        wait for CLK_PERIOD * 2;

        report_line("Checking results...");

        for i in 0 to (DEPTH - 1) loop
            for j in 0 to (WIDTH - 1) loop
                if read_data(j) /= std_logic_vector(to_unsigned(i + j, read_data'length)) then
                    errors := errors + 1;
                end if;
            end loop;
            wait for CLK_PERIOD;
        end loop;

        if errors /= 0 then
            report_line("Test failed with " & integer'image(errors) & " out of " & integer'image(SIZE * SIZE) & " errors.");
        else
            report_line("Test passed with no errors out of " & integer'image(SIZE * SIZE) & " checks.");
        end if;
    end process;

end architecture;