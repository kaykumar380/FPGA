----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/22/2018 10:05:58 AM
-- Design Name: 
-- Module Name: mux_addrs - Behavioral
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

entity mux_addrs is
  Port ( 
         sel: in std_logic_vector (1 downto 0);
         inp : in std_logic_vector(38 downto 0);
         mux_o: out std_logic_vector(12 downto 0)
         );
end mux_addrs;

architecture Behavioral of mux_addrs is

begin

mux_o <= inp (25 downto 13) when sel = "01" else  ---recv
         inp (12 downto 0)  when sel = "10" else
         inp (38 downto 26);


end Behavioral;
