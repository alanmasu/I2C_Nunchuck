library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

library work;
use work.log2_pkg.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


-- SIGNIFICATO DI ALCUNI SEGNALI: 
-- start segnale per iniziare a leggere dal sensore Nunchuck. Non ha senso leggere di continuo se non mi interesssano i dati in quel momento, quando a 1 inizio la transazione di lettura.
-- start segnale in entrata al sensore 
-- valid segnale in uscita dal sensore, posto a 1 quando i dati (accX, accY, accZ) sono pronti (dopo lo stato di elaborate)
-- en segnale che input al driver quando voglio iniziare una transazione singola. (differisce da start per il fatto che la transazione è singola)


entity Nunchuck is
    Port ( clk : in STD_LOGIC;
           res : in STD_LOGIC;
           sda : inout STD_LOGIC;
           scl : inout STD_LOGIC;
           accX : out STD_LOGIC_VECTOR (9 downto 0);
           accY : out STD_LOGIC_VECTOR (9 downto 0);
           accZ : out STD_LOGIC_VECTOR (9 downto 0);
           valid : out std_logic;                           -- dati corretti AccX, AccY, AccZ pronti
           start : in std_logic;
           err : out std_logic
    );
end Nunchuck;

architecture Behavioral of Nunchuck is
    constant BYTE_BUFFER_SIZE : integer := 6;
    type nunchuck_state_t is (init, wait_init, init2, wait_init2, idle, conversion, wait_conversion, reading, wait_reading, elaborate, to_err, pause);                 -- idle segnale per non leggere dati dal sensore
    signal en : STD_LOGIC;
    signal rw_n : STD_LOGIC;
    signal d_in : STD_LOGIC_VECTOR ((BYTE_BUFFER_SIZE * 8) - 1 downto 0);          -- dato in
    signal addr_in : STD_LOGIC_VECTOR (6 downto 0);
    signal d_out : STD_LOGIC_VECTOR ((BYTE_BUFFER_SIZE * 8) - 1 downto 0);         -- comandato dal driver
    signal busy, error : STD_LOGIC;                                              -- comandati dal driver
    signal nunchuck_state : nunchuck_state_t := init;
    signal nunchuck_state_resume : nunchuck_state_t := init;
    signal data_length : STD_LOGIC_VECTOR (clog2(BYTE_BUFFER_SIZE) downto 0);
    signal data_length_out : STD_LOGIC_VECTOR (clog2(BYTE_BUFFER_SIZE) downto 0);
    signal busy_count : unsigned (1 downto 0) := (others => '0');
    signal busy_prev : STD_LOGIC := '0';
    signal pause_counter : unsigned (19 downto 0) := (others => '0');
    constant pause_value : unsigned (19 downto 0) := to_unsigned(50000, 20);
    
begin
    driver : entity work.I2C_driver
    generic map (
        BYTE_BUFF_SIZE => BYTE_BUFFER_SIZE,
        FREQ_KHZ => 100        
    )

    port map (
        clk => clk,
        res => res,
        en => en, 
        addr_in => addr_in,
        rw_n => rw_n, 
        d_in => d_in,
        data_length => data_length,
        d_out => d_out,
        data_length_out => data_length_out,
        busy => busy,
        error => error,                                    
        sda => sda,                                              
        scl => scl
    );

    msf : process( clk, res )
    begin
        if res = '0' then 
            en <= '0';
            accX <= (others => '0');
            accY <= (others => '0');
            accZ <= (others => '0');
            d_in <= (others => '0');
            nunchuck_state <= init;
            valid <= '0';
            err <= '0';
        elsif rising_edge(clk) then
            en <= '0';
            valid <= '0';
            rw_n <= '0';
            addr_in <= "1010010"; --x"0052";
            err <= '0';
            case(nunchuck_state) is
                when init =>
                    busy_prev <= busy;
                    if busy_prev = '0' and busy = '1' then
                        busy_count <= busy_count + 1;
                    end if ;
                    if busy_count = 0 then
                        en <= '1';
                        d_in <= x"0000000055F0";             
                        data_length <= x"2"; 
                    elsif busy_count = 1 then
                        nunchuck_state <= wait_init;
                        busy_count <= (others => '0');
                    end if ;
                when wait_init =>
                    if busy = '1' then 
                        nunchuck_state <= wait_init;
                    else 
                        if error = '0' then  
                            nunchuck_state <= pause;
                            nunchuck_state_resume <= init2;
                            --nunchuck_state_resume <= reading;
                        else 
                            nunchuck_state <= to_err;
                        end if;
                    end if;
                when init2 =>
                    busy_prev <= busy;
                    if busy_prev = '0' and busy = '1' then
                        busy_count <= busy_count + 1;
                    end if ;
                    if busy_count = 0 then
                        en <= '1';
                        d_in <= x"0000000000FB";             
                        data_length <= x"2"; 
                    elsif busy_count = 1 then
                        nunchuck_state <= wait_init2;
                        busy_count <= (others => '0');
                    end if ;
                when wait_init2 =>
                    if busy = '0' then
                        if error = '0' then  
                            nunchuck_state <= pause;
                            nunchuck_state_resume <= conversion;
                        else 
                            nunchuck_state <= to_err;
                        end if;
                    end if;
                when pause =>
                    if pause_counter = pause_value then
                        pause_counter <= (others => '0');
                        nunchuck_state <= nunchuck_state_resume;
                    else
                        pause_counter <= pause_counter + 1;
                        nunchuck_state <= pause;
                    end if;
                when conversion =>
                    busy_prev <= busy;
                    if busy_prev = '0' and busy = '1' then
                        busy_count <= busy_count + 1;
                    end if ;
                    if busy_count = 0 then
                        en <= '1';
                        d_in <= x"000000000000";             
                        data_length <= x"2"; 
                    else 
                        nunchuck_state <= wait_conversion;
                        busy_count <= (others => '0');
                    end if ;
                when wait_conversion =>
                    if busy = '1' then 
                        nunchuck_state <= wait_conversion;
                    else
                        if error = '0' then  
                            nunchuck_state <= pause;
                            nunchuck_state_resume <= reading;
                        else
                            nunchuck_state <= to_err;
                        end if;
                    end if;

                when reading =>
                    busy_prev <= busy;
                    if busy_prev = '0' and busy = '1' then
                        busy_count <= busy_count + 1;
                    end if ;
                    if busy_count = 0 then
                        en <= '1';
                        rw_n <= '1';   
                        data_length <= x"6";
                    else 
                        nunchuck_state <= wait_reading;
                        busy_count <= (others => '0');
                    end if ;    
                when wait_reading =>
                    if busy = '1' then 
                        nunchuck_state <= wait_reading;
                    else
                        nunchuck_state <= elaborate;
                    end if;

                when elaborate =>
                    accX (9 downto 2) <= d_out (31 downto 24);
                    accX (1 downto 0) <= d_out (7 downto 6);
                    accY (9 downto 2) <= d_out (23 downto 16);
                    accY (1 downto 0) <= d_out (5 downto 4);
                    accZ (9 downto 2) <= d_out (15 downto 8);
                    accZ (1 downto 0) <= d_out (3 downto 2);
                    nunchuck_state <= idle;

                when idle =>
                    valid <= '1';
                    busy_count <= (others => '0');
                    if (start = '0') then 
                        nunchuck_state <= idle;
                    else
                        nunchuck_state <= pause;
                        nunchuck_state_resume <= conversion;
                    end if;

                when to_err =>
                    -- so cazzi
                    err <= '1';
                    if start = '1' then
                        nunchuck_state <= idle;
                    end if ;
            end case;
        end if;
    end process msf;                                                    -- msf   

end architecture;