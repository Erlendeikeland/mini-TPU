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

    signal master_enable : std_logic;
    signal master_write_address : natural;
    signal master_write_enable : std_logic;
    signal master_write_data : data_array;
    signal master_read_address : natural;
    signal master_read_data : data_array;
    signal port_0_enable : std_logic;
    signal port_0_write_address : natural;
    signal port_0_write_enable : std_logic;
    signal port_0_write_data : data_array;
    signal port_1_enable : std_logic;
    signal port_1_read_address : natural;
    signal port_1_read_data : data_array;


    type state_t is (IDLE, READ_ADDRESS, READ_DATA_WAIT, READ_DATA, WRITE_ADDRESS, WRITE_DATA_WAIT, WRITE_DATA);
    signal state : state_t;

    signal read_enable : std_logic;
    signal write_enable : std_logic;

    signal read_data_ready : std_logic;
    signal write_data_ready : std_logic;

    signal read_address_reg : std_logic_vector((C_S_AXI_ADDR_WIDTH - 1) downto 0);
    signal write_data_reg : std_logic_vector((C_S_AXI_DATA_WIDTH - 1) downto 0);
    signal write_address_reg : std_logic_vector((C_S_AXI_ADDR_WIDTH - 1) downto 0);

    signal axi_write_ready : std_logic;
    signal axi_read_ready : std_logic;

begin

    unified_buffer_inst: entity work.unified_buffer
        generic map(
            WIDTH => 8,
            DEPTH => 8
        )
        port map(
            clk => S_AXI_ACLK,
            master_enable => master_enable,
            master_write_address => master_write_address,
            master_write_enable => master_write_enable,
            master_write_data => master_write_data,
            master_read_address => master_read_address,
            master_read_data => master_read_data,
            port_0_enable => port_0_enable,
            port_0_write_address => port_0_write_address,
            port_0_write_enable => port_0_write_enable,
            port_0_write_data => port_0_write_data,
            port_1_enable => port_1_enable,
            port_1_read_address => port_1_read_address,
            port_1_read_data => port_1_read_data
        );
    
    process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                state <= IDLE;
            else
                case state is
                    when IDLE =>
                        if S_AXI_AWVALID = '0' and S_AXI_ARVALID = '1' then
                            state <= READ_ADDRESS;
                            read_address_reg <= S_AXI_ARADDR;
                        elsif S_AXI_AWVALID = '1' and S_AXI_ARVALID = '0' then
                            state <= WRITE_ADDRESS;
                            write_address_reg <= S_AXI_AWADDR;
                            write_data_reg <= S_AXI_WDATA;
                        end if;

                    when READ_ADDRESS =>
                        if S_AXI_RREADY = '1' then
                            state <= READ_DATA_WAIT;
                            read_enable <= '1';
                        end if;

                    when READ_DATA_WAIT =>
                        read_enable <= '0';
                        if read_data_ready = '1' then
                            state <= READ_DATA;
                        end if;

                    when READ_DATA =>
                        state <= IDLE;

                    when WRITE_ADDRESS =>
                        if S_AXI_WVALID = '1' then
                            state <= WRITE_DATA_WAIT;
                            write_enable <= '1';
                        end if;
                        
                    when WRITE_DATA_WAIT =>
                        write_enable <= '0';
                        if write_data_ready = '1' then
                            state <= WRITE_DATA;
                        end if;
                        
                    when WRITE_DATA =>
                        state <= IDLE;

                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

    read_data_ready <= read_enable;
    write_data_ready <= write_enable;

    S_AXI_AWREADY <= '1' when state = IDLE else '0';
    S_AXI_ARREADY <= '1' when state = IDLE else '0';
    S_AXI_WREADY <= '1' when state = WRITE_ADDRESS else '0';
    S_AXI_BVALID <= '1' when state = WRITE_DATA else '0';
    S_AXI_BRESP <= "00";

    S_AXI_RVALID <= '1' when state = READ_DATA else '0';
    S_AXI_RRESP <= "00";

end;
