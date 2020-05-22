library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity mode_sel is
  Port ( 
         clk : in std_logic;
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
signal count: integer := 0;
constant max_count : integer := 2000000; -----debouncing delay of 20ms
signal done : std_logic;
type state is (idle,waits,update);
signal curr_state : state := idle;
signal ssw0,ssw1,sres : std_logic:= '0';

begin

process (sw0,sw1,res,clk)
begin
 case curr_state is
  when idle =>
    if clk'event and clk ='1' then
      if sw0 /= ssw0 or sw1 /= ssw1 or res /= sres then
       curr_state <= waits;
       else 
        curr_state <= idle;
       end if; 
   end if;
   
  when waits =>   
   if clk'event and clk = '1' then 
    if count < max_count then 
        count <= count+1;
    else
        count <= 0;
        curr_state <= update;    
    end if;
   end if; 

 when update =>
   ssw0 <= sw0;
   ssw1 <= sw1;
   sres <= res;
   
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
end case;
end process;        

end Behavioral;                   