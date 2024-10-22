library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.env.stop;

use work.minitpu_pkg.all;

entity fifo_tb is
end entity fifo_tb;

architecture rtl of fifo_tb is

    constant CLK_PERIOD : time := 10 ns;
    signal clk : std_logic := '1';
    
    signal reset : std_logic := '0';

    constant DEPTH : natural := 16;
    signal write_data : op_t := (others => '0');
    signal write_en : std_logic := '0';
    signal full : std_logic;
    signal read_data : op_t := (others => '0');
    signal read_en : std_logic := '0';
    signal empty : std_logic;

    type test_array_t is array(0 to (DEPTH - 1)) of op_t;

    procedure write(
        constant data : op_t;
        signal write_data : out op_t;
        signal write_en : out std_logic
    ) is
    begin
        write_data <= data;
        write_en <= '1';
        wait for CLK_PERIOD;
        write_en <= '0';
    end procedure write;

    procedure read(
        signal read_en : out std_logic
    ) is
    begin
        read_en <= '1';
        wait for CLK_PERIOD;
        read_en <= '0';
    end procedure read;

begin

    fifo_inst: entity work.fifo
        generic map(
            DEPTH => DEPTH
        )
        port map(
            clk => clk,
            reset => reset,
            write_en => write_en,
            write_data => write_data,
            full => full,
            read_en => read_en,
            read_data => read_data,
            empty => empty
        );

    clk <= not clk after CLK_PERIOD / 2;

    process
    begin
        wait for CLK_PERIOD;
        reset <= '1';
        wait for CLK_PERIOD;
        reset <= '0';
        wait;
    end process;

    process
        variable seed1, seed2 : integer := 999;
        
        impure function rand_slv(len : integer) return std_logic_vector is
            variable r : real;
            variable slv : std_logic_vector(len - 1 downto 0);
        begin
            for i in slv'range loop
                uniform(seed1, seed2, r);
                slv(i) := '1' when r > 0.5 else '0';
            end loop;
            return slv;
        end function;

        impure function rand_int(min_val, max_val : integer) return integer is
            variable r : real;
        begin
            uniform(seed1, seed2, r);
            return integer(round(r * real(max_val - min_val + 1) + real(min_val) - 0.5));
        end function;

        variable test_array : test_array_t;
        variable test_length : integer;
    begin
        wait for CLK_PERIOD * 5;

        for i in 0 to 100 loop
            test_length := rand_int(1, DEPTH);
            for j in 0 to test_length - 1 loop
                test_array(j) := rand_slv(op_t'length);
                write(test_array(j), write_data, write_en);
            end loop;
            for j in 0 to test_length - 1 loop
                read(read_en);
                wait for CLK_PERIOD;
                assert read_data = test_array(j) report "Mismatch" severity failure;
            end loop;
        end loop;        

        wait for CLK_PERIOD * 5;

        stop;
    end process;

end architecture;