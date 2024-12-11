library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity S00_AXI is
    generic (
        C_S_AXI_DATA_WIDTH	: integer	:= 32;
        C_S_AXI_ADDR_WIDTH	: integer	:= 16
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
    
    type state_t is (
        IDLE,
        READ_DATA,
        READ_WAIT,
        READ_VALID,
        WRITE_FIFO,
        WRITE_VALID,
        WRITE_DATA
    );
    signal state : state_t;

    signal axi_data : std_logic_vector((C_S_AXI_DATA_WIDTH - 1) downto 0);
    signal axi_address : std_logic_vector((C_S_AXI_ADDR_WIDTH - 1) downto 0);

    signal write_fifo_reg : std_logic_vector((C_S_AXI_DATA_WIDTH - 1) downto 0);

    signal last_address : std_logic_vector(15 downto 6);

    signal write_offset : natural range 0 to (BLOCKS - 1);
    signal read_offset : natural range 0 to (BLOCKS - 1);

    signal opcode : std_logic_vector(1 downto 0);
    signal last_opcode : std_logic_vector(1 downto 0);
    
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
        variable read_count : natural range 0 to (UNIFIED_BUFFER_READ_DELAY - 1) + 1;
        variable write_count : natural range 0 to (BLOCKS - 1);

        variable write_data_reg : data_array;
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                state <= IDLE;
                unified_buffer_master_enable <= '0';
                unified_buffer_master_write_enable <= '0';
                weight_buffer_port_0_enable <= '0';
                weight_buffer_port_0_write_enable <= '0';
                fifo_write_enable <= '0';
                write_count := 0;
            else
                case state is
                    when IDLE =>
                        if S_AXI_AWVALID = '0' and S_AXI_ARVALID = '1' then
                            state <= READ_DATA;
                            axi_address <= S_AXI_ARADDR;
                        elsif S_AXI_AWVALID = '1' and S_AXI_ARVALID = '0' then
                            axi_address <= S_AXI_AWADDR;
                            axi_data <= S_AXI_WDATA;
                            if (S_AXI_AWADDR(5 downto 4) = "00") or (S_AXI_AWADDR(5 downto 4) = "01") then
                                state <= WRITE_DATA;
                            elsif (S_AXI_AWADDR(5 downto 4) = "10") then
                                state <= WRITE_FIFO;
                            end if;
                        end if;

                    when WRITE_FIFO =>
                        if S_AXI_WVALID = '1' then
                            fifo_write_enable <= '1';
                            fifo_write_data <= axi_data;
                            state <= WRITE_VALID;
                        end if;

                    when WRITE_DATA =>
                        if S_AXI_WVALID = '1' then
                            state <= WRITE_VALID;

                            for i in 0 to 3 loop
                                write_data_reg(i + (write_offset * 4)) := axi_data(((i * 8) + 7) downto (i * 8));
                            end loop;

                            if (axi_address(15 downto 6) = last_address) and (opcode = last_opcode) then
                                if write_count = (BLOCKS - 2) then
                                    if opcode = "00" then
                                        unified_buffer_master_enable <= '1';
                                        unified_buffer_master_write_enable <= '1';
                                        unified_buffer_master_write_data <= write_data_reg;
                                        unified_buffer_master_write_address <= to_integer(unsigned(axi_address(15 downto 6)));
                                    elsif opcode = "01" then
                                        weight_buffer_port_0_enable <= '1';
                                        weight_buffer_port_0_write_enable <= '1';
                                        for i in 0 to (SIZE - 1) loop
                                            weight_buffer_port_0_write_data(i) <= write_data_reg(i);
                                        end loop;
                                        weight_buffer_port_0_write_address <= to_integer(unsigned(axi_address(15 downto 6)));
                                    end if;
                                    write_count := 0;
                                else
                                    write_count := write_count + 1;
                                end if;
                            else
                                write_count := 0;
                            end if;
                            last_address <= axi_address(15 downto 6);
                            last_opcode <= opcode;
                        end if;
                        
                    when WRITE_VALID =>
                        if opcode = "00" then
                            unified_buffer_master_enable <= '0';
                            unified_buffer_master_write_enable <= '0';
                        elsif opcode = "01" then
                            weight_buffer_port_0_enable <= '0';
                            weight_buffer_port_0_write_enable <= '0';
                        elsif opcode = "10" then
                            fifo_write_enable <= '0';
                        end if;
                        if S_AXI_BREADY = '1' then
                            state <= IDLE;
                        end if;

                    when READ_DATA =>
                        if S_AXI_RREADY = '1' then
                            state <= READ_WAIT;
                            unified_buffer_master_enable <= '1';
                            unified_buffer_master_read_address <= to_integer(unsigned(axi_address(15 downto 6)));
                            read_count := 0;
                        end if;

                    when READ_WAIT =>
                        if read_count = (UNIFIED_BUFFER_READ_DELAY - 1) + 1 then
                            state <= READ_VALID;
                            unified_buffer_master_enable <= '0';
                            for i in 0 to 3 loop
                                S_AXI_RDATA(((i * 8) + 7) downto (i * 8)) <= unified_buffer_master_read_data(i + (read_offset * 4));
                            end loop;
                        else
                            read_count := read_count + 1;
                        end if;

                    when READ_VALID =>
                        state <= IDLE;

                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    S_AXI_AWREADY <= '1' when state = IDLE else '0';
    S_AXI_ARREADY <= '1' when state = IDLE else '0';
    S_AXI_WREADY <= '1' when (state = WRITE_DATA) or (state = WRITE_FIFO) else '0';
    S_AXI_BVALID <= '1' when state = WRITE_VALID else '0';
    S_AXI_BRESP <= "00";

    S_AXI_RVALID <= '1' when state = READ_VALID else '0';
    S_AXI_RRESP <= "00";

    write_offset <= to_integer(unsigned(axi_address(3 downto 2)));
    read_offset <= to_integer(unsigned(axi_address(3 downto 2)));

    opcode <= axi_address(5 downto 4);

end;