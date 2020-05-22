-- BASIC-52 with updated baud rate recognition

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ROM52 is
	port(
		Clk	: in std_logic;
		Din : in std_logic_vector(7 downto 0); ------------
		A	: in std_logic_vector(12 downto 0);
		progk : in std_logic;  
		read_now : in std_logic;                  -------------
		D	: out std_logic_vector(7 downto 0)
		--opcode_out : out std_logic_vector(16383 downto 0)
	);
end ROM52;

architecture rtl of ROM52 is
	signal A_r ,A_r_s: std_logic_vector(12 downto 0); ---------------------
	signal rom_in: std_logic_vector (7 downto 0);
	type type_opcode is array (0 to 2047) of std_logic_vector(7 downto 0);
         signal opcode : type_opcode := (
         "01111000", --mov R0, #F0
         "11110000", 
         "01111001", --mov R1, #F1
         "11110001",
         "01111010", --mov R2, #F2
         "11110010", 
         "01111011", --mov R3, #F3
         "11110011", 
         "01111100", --mov R4, #F4
         "11110100",
         "01111101", --mov R5, #F5
         "11110101",
         "01111110", --mov R6, #F6
         "11110110", 
         "01111111", --mov R7, #F7
         "11110111",
         "01110100", --mov A, #12h
         "00010010",
		 "01110101", --mov p1, 7F
         "10010000",
         "01111111",
         "01110101", --mov p1, AA
         "10010000",
         "01111111",
         "01110101", --mov p2, FF
         "10100000", 
         "01111111",
		 "01110101", --mov p2, 7F
         "10100000", 
         "01111111",
		 "01110101", --mov p0, FF
         "10000000", 
         "01111111",
		 "01110101", --mov p0, 7F
         "10000000", 
         "01111111",
		 "01110101", --mov p3, FF
         "10110000", 
         "01111111",
		 "01110101", --mov p3, 7F
         "10110000", 
         "01111111",
         "00000101", --INC DIR
         "00100000", --20
         "00000101", --INC DIR
         "00101101", --2D
         "00000101", --INC DIR
         "00110011", --33h
         "00000101", --INC DIR
         "01000011", --43h
         "00000101", --INC DIR
         "01010000", --50h
         "00000101", --INC DIR
         "01011100", --5C
         "00000101", --INC DIR
         "01100010", --62h
         "00000101", --INC DIR
         "01101111", --6F
         "00000101", --INC DIR
         "01111111", --7F
         "00000101", --INC DIR
         "10001010", --8A
         "00000101", --INC DIR
         "10001011", --8B
         "00000101", --INC DIR
         "10001100", --8C
         "00000101", --INC DIR
         "10001101", --8D
         others => "00000000"
         );
---------------------------------------------------------kkkk
attribute ram_style: string;
attribute ram_style of opcode : signal is "block";


begin
	process (Clk)
	begin
		if Clk'event and Clk = '1' then
			A_r <= "00" & A(10 downto 0); --------------------------------kkkkkkkkkk
			--rom_in <= Din;
		end if;
	end process;
	---------------------------
--	read_op: process(opcode,A_r,progk)
--	begin
	
--	if clk'event and clk='1' and progk='0' then
--	 D <= opcode(to_integer(unsigned(A_r)));
--	end if;   
--	end process;
read_op: process(A_r)
  begin
	 D <= opcode(to_integer(unsigned(A_r)));  
 end process;
	-----------------------------
	process (progk,read_now)
	begin
	     if progk='1' and read_now'event and read_now ='1' then
                 A_r_s <= "00" & A(10 downto 0); ----------------------------------------kkkkkkkk
                 rom_in <= Din;
         end if;
	end process;
	
	process (progk,read_now)
	begin
         if progk='1' and read_now'event and read_now ='0' then
             opcode(to_integer(unsigned(A_r_s)))<= rom_in;
         end if;
	end process;

--	process(Clk)
--	variable up_range : integer;
--	variable down_range : integer;
--	begin
--		if Clk'event and Clk = '1' then
--			for i in 0 to 2047 loop
--				up_range := i * 8 + 7;
--				down_range := i * 8;
--				opcode_out(up_range downto down_range) <= opcode(i);
--			end loop;
--		end if;
--	end process;
end;