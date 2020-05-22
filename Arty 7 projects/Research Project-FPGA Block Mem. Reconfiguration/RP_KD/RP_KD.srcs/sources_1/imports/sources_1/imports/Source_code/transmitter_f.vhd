library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity transmitter_f is
  generic (
    g_CLKS_PER_BIT : integer := 10416     -- (100,000_000/9600 = 10416.6666)
    );
  port (
    clk         : in  std_logic;
    res_n         : in  std_logic;
    data_ready  : in  std_logic; ---- start transmission
    i_TX_Byte   : in  std_logic_vector(7 downto 0); -- data to be transmitted
    ser_out : out std_logic;   -- Tx line
    index  : out std_logic_vector(12 downto 0) --ROM address
    );
end transmitter_f;
 
 
architecture RTL of transmitter_f is
 
  type t_SM_Main is (s_Idle, s_TX_Start_Bit, s_TX_Data_Bits,
                     s_TX_Stop_Bit, s_Cleanup);
  signal r_SM_Main : t_SM_Main := s_Idle;
 
  signal r_Clk_Count : integer range 0 to g_CLKS_PER_BIT-1 := 0;
  signal r_Bit_Index : integer range 0 to 7 := 0;  
  signal r_TX_Data   : std_logic_vector(7 downto 0) := (others => '0');
  signal r_TX_Done   : std_logic := '0';
  
  signal active,done :  std_logic;
  signal led    :  std_logic_vector(7 downto 0);
  signal res : std_logic;
   
begin
 
 res <= not (res_n);
 led <= i_TX_Byte;
 
 update_index: process (res,r_TX_Done)
       variable v_index: integer:= 0;
       begin
         
         if res ='0' then
             if r_TX_Done'event and r_TX_Done ='0' then
                 if v_index < 2047 then
                 v_index := v_index + 1;
                 else 
                 v_index := 0;
                 end if;
              end if;    
         else v_index := 0;
         end if;
         index <= std_logic_vector(to_unsigned(v_index,13));
      end process;   

    
  p_UART_TX : process (clk,res)
  begin
  if res ='1' then
          r_SM_Main <= s_Idle;
  else   
    
    if rising_edge(clk) then
      
      case r_SM_Main is
 
        when s_Idle =>
          active <= '0';
          ser_out <= '1';         -- Drive Line High for Idle
          r_TX_Done   <= '0';
          r_Clk_Count <= 0;
          r_Bit_Index <= 0;
          r_TX_Data <= "00000000"; -----kk
          
          if data_ready = '1' then
            --r_TX_Data <= i_TX_Byte; -----kkk
            r_SM_Main <= s_TX_Start_Bit;
          else
            r_SM_Main <= s_Idle;
          end if;
 
           
       
        when s_TX_Start_Bit =>
          active <= '1';
          ser_out <= '0';
          --r_TX_Data <= i_TX_Byte;------------kkkk
          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
            r_SM_Main   <= s_TX_Start_Bit;
          else
            r_Clk_Count <= 0;
            r_TX_Data <= i_TX_Byte; ---------kkkkkkkk
            r_SM_Main   <= s_TX_Data_Bits;
          end if;
          
        when s_TX_Data_Bits =>
          ser_out <= r_TX_Data(r_Bit_Index);
           
          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
            r_SM_Main   <= s_TX_Data_Bits;
          else
            r_Clk_Count <= 0;
             
            if r_Bit_Index < 7 then
              r_Bit_Index <= r_Bit_Index + 1;
              r_SM_Main   <= s_TX_Data_Bits;
            else
              r_Bit_Index <= 0;
              r_SM_Main   <= s_TX_Stop_Bit;
            end if;
          end if;

        when s_TX_Stop_Bit =>
          ser_out <= '1';
          if r_Clk_Count < g_CLKS_PER_BIT-1 then
            r_Clk_Count <= r_Clk_Count + 1;
            r_SM_Main   <= s_TX_Stop_Bit;
          else
            r_TX_Done   <= '1';
            r_Clk_Count <= 0;
            r_SM_Main   <= s_Cleanup;
          end if;
 
        when s_Cleanup =>
          active <= '0';
          r_TX_Done   <= '0';
          r_SM_Main   <= s_idle;
          
        when others =>
          r_SM_Main <= s_Idle;
 
      end case;
    end if;
  end if;  
  end process p_UART_TX;
 
  done <= r_TX_Done;
   
end RTL;