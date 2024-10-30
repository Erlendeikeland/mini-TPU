library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.minitpu_pkg.all;

entity S00_AXIS is
    generic (
        BLOCK_SIZE : natural := 128;
        C_S_AXIS_TDATA_WIDTH  : natural := 32
    );
    port (
        S_AXIS_ACLK : in std_logic;
        S_AXIS_ARESETN : in std_logic;
        S_AXIS_TREADY : out std_logic;
        S_AXIS_TDATA : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
        S_AXIS_TSTRB : in std_logic_vector(((C_S_AXIS_TDATA_WIDTH / 8) - 1) downto 0);
        S_AXIS_TLAST : in std_logic;
        S_AXIS_TVALID : in std_logic;

        slave_valid : out std_logic;
        slave_ready : in std_logic;
        slave_data : out std_logic_vector((BLOCK_SIZE - 1) downto 0)
    );
end S00_AXIS;

architecture behave of S00_AXIS is

    constant BUFFER_SIZE : natural := BLOCK_SIZE / C_S_AXIS_TDATA_WIDTH;

    -- Buffer for storing incoming data until we have a full block
    type slave_buffer_t is array(0 to (BUFFER_SIZE - 1)) of std_logic_vector((C_S_AXIS_TDATA_WIDTH - 1) downto 0);
    signal slave_buffer : slave_buffer_t;

    signal slave_buffer_valid : std_logic_vector((BUFFER_SIZE - 1) downto 0);

    signal slave_buffer_slot_valid : std_logic;
    signal slave_buffer_slot_valid_next : std_logic_vector((BUFFER_SIZE - 1) downto 0);

    signal axis_tready : std_logic;

    signal axis_accept : std_logic;
    signal slave_accept : std_logic;

    signal buffer_valid : std_logic;

begin

    process (S_AXIS_ACLK)
    begin
        if rising_edge(S_AXIS_ACLK) then
            if axis_tready = '1' then
                -- Shift data through buffer
                for i in 0 to (BUFFER_SIZE - 2) loop
                    slave_buffer(i) <= slave_buffer(i + 1);
                end loop;
                slave_buffer(BUFFER_SIZE - 1) <= S_AXIS_TDATA;
            end if;
        end if;
    end process;

    process (S_AXIS_ACLK)
    begin
        if rising_edge(S_AXIS_ACLK) then
            if S_AXIS_ARESETN = '0' then
                slave_buffer_valid <= (others => '0');
            else
                if slave_buffer_slot_valid = '1' then
                    slave_buffer_valid <= slave_buffer_slot_valid_next;
                end if;
            end if;
        end if;
    end process;

    process(all)
        variable data_accepted: std_logic_vector(1 downto 0);
    begin
        data_accepted := (axis_accept & slave_accept);
        case(data_accepted) is

            -- New chunk sent in, but no message sent out
            -- Shift in the valid flag along with the data
            when "10" =>
                slave_buffer_slot_valid_next <= '1' & slave_buffer_valid((BUFFER_SIZE - 1) downto 1);

            -- No new chunk sent in, message is sent out
            -- Clear all flags. The message buffer is now empty
            when "01" =>
                slave_buffer_slot_valid_next <= (others =>'0');

            -- New chunk in and message sent out
            -- Clear all flags except for the first chunk
            when "11" =>
                slave_buffer_slot_valid_next <= ((BUFFER_SIZE - 1) => '1', others =>'0');

            -- Neither new chunks in nor any message sent out
            -- Do not change any valid flags
            when others => --when "00" =>
                slave_buffer_slot_valid_next <= slave_buffer_valid;

        end case;
    end process;

    buffer_valid <= and slave_buffer_valid;

    S_AXIS_TREADY <= axis_tready;
    axis_tready <= slave_ready and (not buffer_valid);
    axis_accept <= axis_tready and S_AXIS_TVALID;
    
    slave_valid <= buffer_valid;
    slave_accept <= slave_ready and buffer_valid;

    slave_buffer_slot_valid <= axis_accept or slave_accept;
    

end;