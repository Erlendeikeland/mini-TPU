library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity S00_AXI is
    generic (
        C_S_AXI_DATA_WIDTH	: integer	:= 32;
        C_S_AXI_ADDR_WIDTH	: integer	:= 20
    );
    port (
        S_AXI_ACLK : in std_logic;
        S_AXI_ARESETN : in std_logic;
        -- Write address channel
        S_AXI_AWADDR : in std_logic_vector((C_S_AXI_ADDR_WIDTH - 1) downto 0);
        S_AXI_AWPROT : in std_logic_vector(2 downto 0);
        S_AXI_AWVALID : in std_logic;
        S_AXI_AWREADY : out std_logic;
        -- Write address channel
        S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
        S_AXI_WSTRB	: in std_logic_vector(((C_S_AXI_DATA_WIDTH / 8) - 1) downto 0);
        S_AXI_WVALID : in std_logic;
        S_AXI_WREADY : out std_logic;
        -- Write response channel
        S_AXI_BRESP	: out std_logic_vector(1 downto 0);
        S_AXI_BVALID : out std_logic;
        S_AXI_BREADY : in std_logic;
        -- Read address channel
        S_AXI_ARADDR : in std_logic_vector((C_S_AXI_ADDR_WIDTH - 1) downto 0);
        S_AXI_ARPROT : in std_logic_vector(2 downto 0);
        S_AXI_ARVALID : in std_logic;
        S_AXI_ARREADY : out std_logic;
        -- Read data interface
        S_AXI_RDATA	: out std_logic_vector((C_S_AXI_DATA_WIDTH - 1) downto 0);
        S_AXI_RRESP	: out std_logic_vector(1 downto 0);
        S_AXI_RVALID : out std_logic;
        S_AXI_RREADY : in std_logic
    );
end S00_AXI;

architecture behave of S00_AXI is

    signal fifo_write_enable : std_logic;
    signal fifo_write_data : op_t;

    signal weight_buffer_port_0_enable : std_logic;
    signal weight_buffer_port_0_write_data : weight_array;
    signal weight_buffer_port_0_write_address : natural range 0 to (WEIGHT_BUFFER_DEPTH - 1);
    signal weight_buffer_port_0_write_enable : std_logic;

    signal unified_buffer_master_enable : std_logic;
    signal unified_buffer_master_write_data : data_array;
    signal unified_buffer_master_write_address : natural range 0 to (UNIFIED_BUFFER_DEPTH - 1);
    signal unified_buffer_master_write_enable : std_logic;
    signal unified_buffer_master_read_address : natural range 0 to (UNIFIED_BUFFER_DEPTH - 1);
    signal unified_buffer_master_read_data : data_array;

    constant BLOCKS : natural := (DATA_WIDTH * SIZE) / C_S_AXI_DATA_WIDTH;
    
    type state_t is (IDLE, READ_ADDRESS, READ_DATA_WAIT_0, READ_DATA_WAIT_1, READ_DATA, WRITE_ADDRESS, WRITE_FIFO, WRITE_DATA_WAIT, WRITE_DATA);
    signal state : state_t;

    signal read_enable : std_logic;
    signal write_enable : std_logic;

    signal write_data_reg : std_logic_vector(((DATA_WIDTH * SIZE) - 1) downto 0);
    signal write_address_reg : std_logic_vector(19 downto 4);
    signal read_address_reg : std_logic_vector((C_S_AXI_ADDR_WIDTH - 1) downto 0);
    signal last_address : std_logic_vector(19 downto 6);

    signal write_data_reg_0 : std_logic_vector(((DATA_WIDTH * SIZE) - 1) downto 0);
    signal write_data_reg_1 : std_logic_vector(((DATA_WIDTH * SIZE) - 1) downto 0);

    signal write_address_reg_0 : std_logic_vector(19 downto 4);
    signal write_address_reg_1 : std_logic_vector(19 downto 4);

    signal write_enable_reg_0 : std_logic;
    signal write_enable_reg_1 : std_logic;

begin

    tpu_inst: entity work.tpu
        port map(
            clk => S_AXI_ACLK,
            reset => S_AXI_ARESETN,
            fifo_write_enable => fifo_write_enable,
            fifo_write_data => fifo_write_data,
            weight_buffer_port_0_enable => weight_buffer_port_0_enable,
            weight_buffer_port_0_write_data => weight_buffer_port_0_write_data,
            weight_buffer_port_0_write_address => weight_buffer_port_0_write_address,
            weight_buffer_port_0_write_enable => weight_buffer_port_0_write_enable,
            unified_buffer_master_enable => unified_buffer_master_enable,
            unified_buffer_master_write_address => unified_buffer_master_write_address,
            unified_buffer_master_write_enable => unified_buffer_master_write_enable,
            unified_buffer_master_write_data => unified_buffer_master_write_data,
            unified_buffer_master_read_address => unified_buffer_master_read_address,
            unified_buffer_master_read_data => unified_buffer_master_read_data
        );
    
    process (S_AXI_ACLK)
        variable count : natural range 0 to (BLOCKS - 1);
        variable write_index : natural range 0 to (BLOCKS - 1);
        variable read_index : natural range 0 to (BLOCKS - 1);
        variable read_wait : natural range 0 to UNIFIED_BUFFER_READ_DELAY - 1;
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                state <= IDLE;
                write_enable <= '0';
                read_enable <= '0';
                count := 0;
            else
                case state is
                    when IDLE =>
                        if S_AXI_AWVALID = '0' and S_AXI_ARVALID = '1' then
                            state <= READ_ADDRESS;
                            read_address_reg <= S_AXI_ARADDR;
                        elsif S_AXI_AWVALID = '1' and S_AXI_ARVALID = '0' then
                            write_address_reg <= S_AXI_AWADDR(19 downto 4);
                            if (S_AXI_AWADDR(5 downto 4) = "00") or (S_AXI_AWADDR(5 downto 4) = "01") then
                                write_index := to_integer(unsigned(S_AXI_AWADDR(3 downto 2)));
                                write_data_reg(((write_index * C_S_AXI_DATA_WIDTH) + (C_S_AXI_DATA_WIDTH - 1)) downto (write_index * C_S_AXI_DATA_WIDTH)) <= S_AXI_WDATA;
                                state <= WRITE_ADDRESS;
                            elsif (S_AXI_AWADDR(5 downto 4) = "10") then
                                write_data_reg(31 downto 0) <= S_AXI_WDATA;
                                state <= WRITE_FIFO;
                            end if;
                        end if;

                    when READ_ADDRESS =>
                        if S_AXI_RREADY = '1' then
                            read_enable <= '1';
                            state <= READ_DATA_WAIT_0;
                            read_wait := 0;
                        end if;

                    when READ_DATA_WAIT_0 =>
                        read_enable <= '0';
                        if read_wait = (UNIFIED_BUFFER_READ_DELAY - 1) then
                            state <= READ_DATA_WAIT_1;
                        else
                            read_wait := read_wait + 1;
                        end if;
                        
                    when READ_DATA_WAIT_1 =>
                        read_index := to_integer(unsigned(read_address_reg(3 downto 2)));

                        for i in 0 to 3 loop
                            S_AXI_RDATA(((i * 8) + 7) downto (i * 8)) <= unified_buffer_master_read_data(i + (4 * read_index));
                        end loop;
                        state <= READ_DATA;

                    when READ_DATA =>
                        state <= IDLE;

                    when WRITE_ADDRESS =>
                        if S_AXI_WVALID = '1' then
                            state <= WRITE_DATA_WAIT;
                            if write_address_reg(19 downto 6) = last_address then
                                if count = (BLOCKS - 2) then
                                    write_enable <= '1';
                                    write_address_reg <= write_address_reg(19 downto 4);
                                    count := 0;
                                else
                                    count := count + 1;
                                end if;
                            else
                                count := 0;
                            end if;
                            last_address <= write_address_reg(19 downto 6);
                        end if;

                    when WRITE_FIFO =>
                        if S_AXI_WVALID = '1' then
                            state <= WRITE_DATA_WAIT;
                            write_enable <= '1';
                        end if;
                        
                    when WRITE_DATA_WAIT =>
                        write_enable <= '0';
                        state <= WRITE_DATA;
                        
                    when WRITE_DATA =>
                        if S_AXI_BREADY = '1' then
                            state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    S_AXI_AWREADY <= '1' when state = IDLE else '0';
    S_AXI_ARREADY <= '1' when state = IDLE else '0';
    S_AXI_WREADY <= '1' when (state = WRITE_ADDRESS) or (state = WRITE_FIFO) else '0';
    S_AXI_BVALID <= '1' when state = WRITE_DATA else '0';
    S_AXI_BRESP <= "00";

    S_AXI_RVALID <= '1' when state = READ_DATA else '0';
    S_AXI_RRESP <= "00";

    unified_buffer_master_enable <= '1' when (write_enable_reg_1 = '1' and (write_address_reg_1(5 downto 4) = "00")) or read_enable = '1' else '0';
    unified_buffer_master_write_enable <= '1' when (write_enable_reg_1 = '1') and (write_address_reg_1(5 downto 4) = "00") else '0';
    unified_buffer_master_write_address <= to_integer(unsigned(write_address_reg_1(19 downto 6)));
    
    unified_buffer_master_read_address <= to_integer(unsigned(read_address_reg(19 downto 6)));

    weight_buffer_port_0_enable <= '1' when (write_enable_reg_1 = '1') and (write_address_reg_1(5 downto 4) = "01") else '0';
    weight_buffer_port_0_write_enable <= '1' when (write_enable_reg_1 = '1') and (write_address_reg_1(5 downto 4) = "01") else '0';
    weight_buffer_port_0_write_address <= to_integer(unsigned(write_address_reg_1(19 downto 6)));

    fifo_write_enable <= '1' when write_enable_reg_1 = '1' and write_address_reg_1(5 downto 4) = "10" else '0';

    process (all)
    begin
        for i in 0 to (SIZE - 1) loop
            unified_buffer_master_write_data(i) <= write_data_reg_1(((i * 8) + 7) downto (i * 8));
        end loop;

        for i in 0 to (SIZE - 1) loop
            weight_buffer_port_0_write_data(i) <= write_data_reg_1(((i * 8) + 7) downto (i * 8));
        end loop;

        fifo_write_data <= write_data_reg_1(31 downto 0);
    end process;

    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            write_data_reg_0 <= write_data_reg;
            write_data_reg_1 <= write_data_reg_0;

            write_address_reg_0 <= write_address_reg(19 downto 4);
            write_address_reg_1 <= write_address_reg_0;

            write_enable_reg_0 <= write_enable;
            write_enable_reg_1 <= write_enable_reg_0;
        end if;
    end process;
end;