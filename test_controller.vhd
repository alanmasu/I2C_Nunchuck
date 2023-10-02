----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/15/2023 02:11:30 PM
-- Design Name: 
-- Module Name: test_controller - Behavioral
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

entity test_controller is
--  Port ( );
end test_controller;

architecture Behavioral of test_controller is
    signal clk : std_logic := '0';
    signal res : std_logic := '0';
    signal sda : STD_LOGIC := '0';
    signal scl : STD_LOGIC := '0';
    signal err : std_logic := '0';
    signal valid : std_logic := '0';
    signal start : std_logic := '0';
begin
    dut : entity work.top_level
    port map(
        clk => clk,
        res => res,
        sda => sda,
        scl => scl,
        err => err,
        valid => valid,
        start => start,
        oled_poweroff => '0'
    );

    clk_gen : process begin
        clk <= '1';
        wait for 5 ns;
        clk <= '0';
        wait for 5 ns;
    end process ; -- clk_gen

    res_gen : process begin
        res <= '0';
        wait for 9 ns;
        res <= '1';
        wait;
    end process ; -- res_gen

    test_pro : process begin
        scl <= 'H';
        sda <= 'H';
        start <= '1';
        wait for 21.4 us;
        start <= '0';
        sda <= '0';         --Init Address ACK
        wait for 1.76 us;
        sda <= 'H';

        wait for 20.685 us;
        sda <= '0';         --Init Command ACK
        wait for 1.81 us;
        sda <= 'H';

        wait for 20.69 us;
        sda <= '0';         --Init Command ACK
        wait for 1.81 us;
        sda <= 'H';

        wait for 23.97 us;
        sda <= '0';         --Init2 Address ACK
        wait for 1.70 us;
        sda <= 'H';

        wait for 21.15 us;
        sda <= '0';         --Init2 Command ACK
        wait for 1.91 us;
        sda <= 'H';

        wait for 20.73 us;
        sda <= '0';         --Init2 Command ACK
        wait for 1.85 us;
        sda <= 'H';

        wait for 24.07 us;
        sda <= '0';         --Conv Address ACK
        wait for 1.81 us;
        sda <= 'H';

        wait for 20.85 us;
        sda <= '0';         --Conv Command ACK
        wait for 1.81 us;
        sda <= 'H';

        wait for 46.49 us;
        sda <= '0';         --Read Address ACK
        wait for 1.85 us;
        sda <= 'H';



        wait;
    end process ; -- test_pro

end Behavioral;
