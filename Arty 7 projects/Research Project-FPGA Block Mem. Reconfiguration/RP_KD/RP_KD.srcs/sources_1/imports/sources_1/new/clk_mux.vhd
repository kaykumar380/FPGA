----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/16/2018 01:46:05 PM
-- Design Name: 
-- Module Name: clk_mux - Behavioral
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

entity clk_mux is
 Port ( 
       cor_clk : in std_logic;
       cons_clk: in std_logic;
       clk_sel : in std_logic;
       clk_out: out std_logic 
 
   );
end clk_mux;

architecture Behavioral of clk_mux is

begin

clk_out <= cons_clk when clk_sel = '1' else
           cor_clk; 

end Behavioral;
