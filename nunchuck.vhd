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
    type nunchuck_state_t is (init, wait_init, idle, conversion, wait_conversion, reading, wait_reading, elaborate, to_err);                 -- idle segnale per non leggere dati dal sensore
    signal en : STD_LOGIC;
    signal rw_n : STD_LOGIC;
    signal d_in : STD_LOGIC_VECTOR ((BYTE_BUFFER_SIZE * 8) - 1 downto 0);          -- dato in
    signal addr_in : STD_LOGIC_VECTOR (6 downto 0);
    signal d_out : STD_LOGIC_VECTOR ((BYTE_BUFFER_SIZE * 8) - 1 downto 0);         -- comandato dal driver
    signal busy, error : STD_LOGIC;                                              -- comandati dal driver
    signal nunchuck_state : nunchuck_state_t := init;
    signal data_length : STD_LOGIC_VECTOR (clog2(BYTE_BUFFER_SIZE) downto 0);
    signal data_length_out : STD_LOGIC_VECTOR (clog2(BYTE_BUFFER_SIZE) downto 0);

begin
    driver : entity work.I2C_driver
    generic map (
        BYTE_BUFF_SIZE => BYTE_BUFFER_SIZE                
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
                    en <= '1';
                    d_in <= x"0000000055F0";             
                    data_length <= x"2"; 
                    nunchuck_state <= wait_init;

                when wait_init =>
                    if busy = '1' then 
                        nunchuck_state <= wait_init;
                    else 
                        if error = '0' then  
                            nunchuck_state <= conversion;
                        else 
                            nunchuck_state <= to_err;
                        end if;
                    end if;

                when conversion =>
                    en <= '1';
                    d_in <= x"000000000000";             
                    data_length <= x"1"; 
                    nunchuck_state <= wait_conversion;

                when wait_conversion =>
                    if busy = '1' then 
                        nunchuck_state <= wait_conversion;
                    else
                        if error = '0' then  
                            nunchuck_state <= reading;
                        else
                            nunchuck_state <= to_err;
                        end if;
                    end if;

                when reading =>
                    en <= '1';
                    rw_n <= '1';        
                    nunchuck_state <= wait_reading;

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
                    if (start = '0') then 
                        nunchuck_state <= idle;
                    else
                        nunchuck_state <= conversion;
                    end if;

                when to_err =>
                    -- so cazzi
                    err <= '1';

            end case;
        end if;
    end process msf;                                                    -- msf   

end architecture;