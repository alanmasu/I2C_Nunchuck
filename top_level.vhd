----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/15/2023 12:22:18 PM
-- Design Name: 
-- Module Name: top_level - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_level is
    Port (
        clk : in std_logic;
        res : in std_logic;
        sda : inout STD_LOGIC;
        scl : inout STD_LOGIC;
        err : out std_logic;
        valid : out std_logic;
        start : out std_logic;
        oled_sdin : out std_logic;                      -- OLED SPI data out
        oled_sclk : out std_logic;                      -- OLED SPI clock
        oled_dc : out   std_logic;                      -- OLED data/command signal
        oled_res : out  std_logic;                      -- OLED reset signal
        oled_vbat : out std_logic;                      -- OLED Vbat enable
        oled_vdd : out  std_logic;                      -- OLED Vdd enable
        oled_poweroff : in std_logic                    -- OLED power off signal
    );
end top_level;

architecture Behavioral of top_level is
    signal display_in : std_logic_vector( 31 downto 0 );
    signal sda_int, scl_int : std_logic := '1';
    signal accX_int :  STD_LOGIC_VECTOR (9 downto 0);
begin

    DRIVER : entity work.oled_driver 
    port map(
        clock => clk,
        reset => res,
        poweroff => oled_poweroff,
        display_in => display_in,
        oled_sdin => oled_sdin,
        oled_sclk => oled_sclk,
        oled_dc => oled_dc,
        oled_res => oled_res,
        oled_vbat => oled_vbat,
        oled_vdd => oled_vdd
    );

    dut : entity work.nunchuck
    port map(
        clk => clk,
        res => res,
        sda => sda,
        scl => scl,
        err => err,
        accX => accX_int,
        start => start,
        valid => valid
    );

    display_in(31 downto 10) <= (others => '0');
    display_in(9 downto 0) <= accX_int;

end Behavioral;
