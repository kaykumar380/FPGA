----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/09/2018 03:31:20 PM
-- Design Name: 
-- Module Name: receiver_1 - Behavioral
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity receiver_1 is
   generic (
     count_per_bit : integer := 10416    -- (100,000_000/9600 = 10416.6666)
    );
    port
    (
        clk         : in  std_logic;                    -- clock 100 mhz
        res_n         : in  std_logic;                    -- reset (high active)
        ser_in      : in  std_logic;                    -- serial data (rx line)
        --recv_data   : out std_logic_vector(7 downto 0); -- data
        int_recv    : out std_logic;                    -- interrupt received
       -- int_ack     : in  std_logic;                     -- interrupt acknowledge
        led         : out std_logic_vector (7 downto 0);
        index     : out std_logic_vector (12 downto 0)
    );
end entity receiver_1;

architecture behavioral of receiver_1 is

  type   state is (st_sample, st_startBit, st_dataBits ,st_error_handl, st_ack );
  signal curr_state  : state;
  signal next_state  : state;
  signal set_count   : std_logic;
  signal curr_count : integer;
  signal s_int_recv : std_logic;
  signal indx: integer;
--
-- signal curr_count : integer range 0 to count_per_bit:= 0;
----
--  signal indx: integer range 0 to 9 := 0;
  signal temp: std_logic_vector(7 downto 0);
  
  signal res :  std_logic ;
    signal int_ack : std_logic := '1';
 -- signal int_recv    :  std_logic; 
  
begin

    ------------------------------
    -- your hw description here
    ------------------------------
    res <= not (res_n);
    
-- update_index: process
--      variable v_index: integer:= 0;
--      begin
--        wait until s_int_recv'event and s_int_recv = '1'; 
--        if res ='0' then
--            if v_index < 2047 then
--            v_index := v_index + 1;
--            else 
--            v_index := 0;
--            end if;
--        else v_index := 0;
--        end if;
        
--       -- if spit='1' then
--        index <= std_logic_vector(to_unsigned(v_index,13));
--        --else
--        --index <= (others=> '0');
--        --end if;
--     end process;   
    
update_index: process (res,s_int_recv)
      variable v_index: integer:= 0;
      begin
        
        if res ='0' then
		    if s_int_recv'event and s_int_recv='0' then
                if v_index < 2047 then
                v_index := v_index + 1;
                else 
                v_index := 0;
                end if;
			 end if;	
        else v_index := 0;
        end if;
        
       -- if spit='1' then
        index <= std_logic_vector(to_unsigned(v_index,13));
        --else
        --index <= (others=> '0');
        --end if;
     end process;   

    
    
p_states : process(clk,res,set_count, curr_count, indx)

begin
        if res='1' then
                curr_count<=0;
                indx <= 0;
                curr_state <= st_sample;
                temp <= (others => '0'); 
        else
                if rising_edge(clk)  then
                        curr_state <= next_state;

                        if set_count='1' then
                                indx<= 0;
                                curr_count<=0;
                        else
                                -- calculate bit time and bit index
                                if curr_count < (count_per_bit) then
                                        curr_count<=curr_count+1;
                                else
                                        indx <= indx + 1;
                                        curr_count<=0;
                                end if;

                                -- sample date in the middle of the bit time
                                if curr_count = (count_per_bit/2) then
                                        if (indx >= 1 and indx <= 8) then
                                                temp(indx-1)<= ser_in;
                                        end if;
                                end if;
                        end if;
                end if;
        end if;
        --end if;
end process;

--  process(curr_count)
--  begin
--  if curr_count =3 then
--   set_count<='1';
--        end if;
--        end process;
--
p_transition: process (curr_state,ser_in,int_ack,indx,curr_count)

begin
        next_state <= curr_state;

        case curr_state is

                when  st_sample =>
                        if ser_in='0' then
                                next_state <= st_startBit;
                        end if;

                when st_startBit =>
                        if curr_count=5208 and ser_in /='0' then
                                next_state <= st_sample;
                        elsif curr_count= count_per_bit then
                                next_state <= st_dataBits;
                        end if;

                when st_dataBits =>
                        if indx=9 and curr_count=(count_per_bit/2)  then
                                if ser_in='1' then
                                        next_state<= st_ack;
                                else
                                        next_state <= st_error_handl;
                                end if;
                        end if;


                when st_ack =>
                        if int_ack='1' and curr_count = count_per_bit then ------------kkkkkk
                                next_state <= st_sample;
                        end if;

                when st_error_handl =>
                        next_state <= st_sample;


                when others =>
                        next_state <=st_sample;

        end case;
end process;

p_output : process(curr_state) --kk

begin
        case curr_state is

                when st_sample =>
                        set_count<='1';
                        s_int_recv <='0';

                when st_startBit =>
                        set_count<='0';
                        s_int_recv <='0';

                when st_dataBits =>
                        set_count<='0';
                        s_int_recv <='0';

                when st_ack =>
                        set_count<='0';
                        s_int_recv <='1';

                when others =>
                        set_count <= '1';
                        s_int_recv <='0';

        end case;
end process;

--recv_data <= temp;
--- NEW -----
int_recv <= s_int_recv;
led <= temp;
--------------
end behavioral;