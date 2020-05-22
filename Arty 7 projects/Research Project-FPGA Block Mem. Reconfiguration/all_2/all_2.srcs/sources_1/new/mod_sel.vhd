library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity mode_sel is
  Port ( 
         res : in std_logic;
         sw1 : in std_logic;
         sw0: in std_logic;
         mux_sel: out std_logic_vector (1 downto 0);
         core_res : out std_logic;
         data_ready: out std_logic;
         rom_read_en : out std_logic;
         clk_sel : out std_logic
  );
end mode_sel;

architecture Behavioral of mode_sel is


begin
  
process (sw0,sw1,res)
begin
  if res = '0' then
   core_res <= '0';
   mux_sel <= "00";
   data_ready <= '0';
   rom_read_en <= '0';
   clk_sel <= '0';
  else 
    if sw0 = '0' and sw1 /= '0' then --sw0 pressed/recv
            core_res <= '0';
            mux_sel <= "01";
            data_ready <= '0'; 
            rom_read_en <= '1';
            clk_sel <= '1';
    elsif sw0 /= '0' and sw1 = '0' then --sw1 pressed
            core_res <= '0';
            mux_sel <= "10";
            data_ready <= '1'; 
            rom_read_en <= '0';
            clk_sel <= '1';
    else
         core_res <= '1';  -- core running
         mux_sel <= "00";
         data_ready <= '0';
         rom_read_en <= '0';
         clk_sel <= '0';               
    end if;
 end if; 

end process; 
end Behavioral;                   