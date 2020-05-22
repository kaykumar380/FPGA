----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.10.2017 21:22:43
-- Design Name: 
-- Module Name: lcd_controller - Behavioral
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
USE IEEE.STD_LOGIC_ARITH.all;
USE IEEE.NUMERIC_STD.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;

entity lcd_controller is
    Port ( clk : in STD_LOGIC;
           lcd_en : out STD_LOGIC;
           lcd_rw : out STD_LOGIC;
           lcd_rs : out STD_LOGIC;
           lcd_data : out STD_LOGIC_VECTOR (7 downto 0);
           fn_sw : in STD_LOGIC_VECTOR (1 downto 0);
           up : in STD_LOGIC;
           down : in STD_LOGIC;
           s100 : in STD_LOGIC;
           lcd_data_alu : in std_logic_vector(55 downto 0);
           lcd_data_pcon_tcon_ie : in std_logic_vector(23 downto 0);
           lcd_data_p0 : in std_logic_vector(7 downto 0);
           lcd_data_p1 : in std_logic_vector(7 downto 0);
           lcd_data_p2 : in std_logic_vector(7 downto 0);
           lcd_data_p3 : in std_logic_vector(7 downto 0);
           lcd_data_uart : in std_logic_vector(15 downto 0);
           lcd_data_timer : in std_logic_vector(39 downto 0);
           lcd_data_opcode_in : in std_logic_vector(16383 downto 0);
           lcd_data_ram_in : in std_logic_vector(1023 downto 0)
           );
end lcd_controller;

architecture Behavioral of lcd_controller is
type state_type is (pw_on, pw_on_2, wait_100ms, wait_100ms_2, fn_set, extended_fn_set, entry_mode_set, bias_set, fn_set_2, int_osc, follower_ctrl, power_ctrl, contrast_set, 
						fn_set_3, display_on, display_data, load_data, hold, home_command);
	type register_array is array (0 to 7) of std_logic_vector(7 downto 0);
	type print_string_type is array (0 to 3, 0 to 19) of std_logic_vector(7 downto 0);
	
	subtype dm_page_type_range is integer range 1 to 7 ;
	subtype pm_page_type_range is integer range 1 to 101 ;
	subtype dm_index_range is integer range 0 to 144 ;
	subtype pm_index_range is integer range 0 to 2056 ;
	subtype column_range is integer range 1 to 20;
	
	--R0; R1; R2 --R3; R4; R5 --R6; R7; ACC --B; IP; PSW
	signal print_string_reg: print_string_type := 
	((x"20", x"52", x"30", x"3D", x"30", x"30", x"20", x"52", x"31", x"3D", x"30", x"30", x"20", x"52", x"32", x"3D", x"30", x"30", x"20", x"20"),
	(x"20", x"52", x"33", x"3D", x"30", x"30", x"20", x"52", x"34", x"3D", x"30", x"30", x"20", x"52", x"35", x"3D", x"30", x"30", x"20", x"20"),
	(x"20", x"52", x"36", x"3D", x"30", x"30", x"20", x"52", x"37", x"3D", x"30", x"30", x"20", x"41", x"43", x"43", x"3D", x"30", x"30", x"20"),
	(x"20", x"20", x"42", x"3D", x"30", x"30", x"20", x"49", x"50", x"3D", x"30", x"30", x"20", x"50", x"53", x"57", x"3D", x"30", x"30", x"20"));
	--SP; DPH; DPL --PCON; IE; --TCON; P0; P1; --TMOD; P2; P3 
	signal print_string_reg_2: print_string_type := 
	((x"53", x"50", x"3D", x"30", x"30", x"20", x"44", x"50", x"48", x"3D", x"30", x"30", x"20", x"44", x"50", x"4C", x"3D", x"30", x"30", x"20"),
	(x"50", x"43", x"4F", x"4E", x"3D", x"30", x"30", x"20", x"49", x"45", x"3D", x"30", x"30", x"20", x"20", x"20", x"20", x"20", x"20", x"20"),
	(x"54", x"43", x"4F", x"4E", x"3D", x"30", x"30", x"20", x"50", x"30", x"3D", x"30", x"30", x"20", x"50", x"31", x"3D", x"30", x"30", x"20"),
	(x"54", x"4D", x"4F", x"44", x"3D", x"30", x"30", x"20", x"50", x"32", x"3D", x"30", x"30", x"20", x"50", x"33", x"3D", x"30", x"30", x"20"));
	--SBUF; SCON --TH1; TL1	--TH0; TL0
	signal print_string_reg_3: print_string_type := 
	((x"53", x"42", x"55", x"46", x"3D", x"30", x"30", x"20", x"53", x"43", x"4F", x"4E", x"3D", x"30", x"30", x"20", x"20", x"20", x"20", x"20"),
	(x"54", x"48", x"31", x"3D", x"30", x"30", x"20", x"54", x"4C", x"31", x"3D", x"30", x"30", x"20", x"20", x"20", x"20", x"20", x"20", x"20"),
	(x"54", x"48", x"30", x"3D", x"30", x"30", x"20", x"54", x"4C", x"30", x"3D", x"30", x"30", x"20", x"20", x"20", x"20", x"20", x"20", x"20"),
	(x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20", x"20"));

	signal state : state_type := pw_on;
	signal next_state : state_type := pw_on;
	signal down_last : std_logic := '1';
	signal up_last : std_logic := '1';
	signal s100_last : std_logic := '1';
	signal fn_sw_last : std_logic_vector(1 downto 0);
	signal dm_column, pm_column : column_range := 1;
	type opcode_type is array (0 to 2056) of std_logic_vector(7 downto 0);
	signal opcode : opcode_type;
	type IRAMA_type is array (0 to 127) of std_logic_vector(7 downto 0);
    signal IRAMA : IRAMA_type;
	signal PSW_data :std_logic_vector(7 downto 0);
begin

    process(clk)
		variable i : integer := 0;
		variable register_val : register_array;
	begin
		if(rising_edge(clk)) then
			if PSW_data(3) = '0' and PSW_data(4) = '0' then
				i := 0;
			elsif PSW_data(3) = '1' and PSW_data(4) = '0' then
				i := 8;
			elsif PSW_data(3) = '0' and PSW_data(4) = '1' then
				i := 16;
			else
				i := 24;
			end if;
			register_val(0) := IRAMA(i);
			register_val(1) := IRAMA(i + 1);
			register_val(2) := IRAMA(i + 2);
			register_val(3) := IRAMA(i + 3);
			register_val(4) := IRAMA(i + 4);
			register_val(5) := IRAMA(i + 5);
			register_val(6) := IRAMA(i + 6);
			register_val(7) := IRAMA(i + 7);
-----------------------------page 1----------------------------	
-------------------R0-R7---------------------------------------			
				if register_val(0)(7 downto 4) > 9 then
					print_string_reg(0,4) <=  x"4" & (register_val(0)(7 downto 4) - 9);
				else
					print_string_reg(0,4) <=  x"3" & register_val(0)(7 downto 4);
				end if;
				if register_val(0)(3 downto 0) > 9 then
					print_string_reg(0,5) <=  x"4" & (register_val(0)(3 downto 0) - 9);
				else
					print_string_reg(0,5) <=  x"3" & register_val(0)(3 downto 0);
				end if;
				
				if register_val(1)(7 downto 4) > 9 then
					print_string_reg(0,10) <=  x"4" & (register_val(1)(7 downto 4) - 9);
				else
					print_string_reg(0,10) <=  x"3" & register_val(1)(7 downto 4);
				end if;
				if register_val(1)(3 downto 0) > 9 then
					print_string_reg(0,11) <=  x"4" & (register_val(1)(3 downto 0) - 9);
				else
					print_string_reg(0,11) <=  x"3" & register_val(1)(3 downto 0);
				end if;
				
				if register_val(2)(7 downto 4) > 9 then
					print_string_reg(0,16) <=  x"4" & (register_val(2)(7 downto 4) - 9);
				else
					print_string_reg(0,16) <=  x"3" & register_val(2)(7 downto 4);
				end if;
				if register_val(2)(3 downto 0) > 9 then
					print_string_reg(0,17) <=  x"4" & (register_val(2)(3 downto 0) - 9);
				else
					print_string_reg(0,17) <=  x"3" & register_val(2)(3 downto 0);
				end if;
				
				if register_val(3)(7 downto 4) > 9 then
					print_string_reg(1,4) <=  x"4" & (register_val(3)(7 downto 4) - 9);
				else
					print_string_reg(1,4) <=  x"3" & register_val(3)(7 downto 4);
				end if;
				if register_val(3)(3 downto 0) > 9 then
					print_string_reg(1,5) <=  x"4" & (register_val(3)(3 downto 0) - 9);
				else
					print_string_reg(1,5) <=  x"3" & register_val(3)(3 downto 0);
				end if;
				
				if register_val(4)(7 downto 4) > 9 then
					print_string_reg(1,10) <=  x"4" & (register_val(4)(7 downto 4) - 9);
				else
					print_string_reg(1,10) <=  x"3" & register_val(4)(7 downto 4);
				end if;
				if register_val(4)(3 downto 0) > 9 then
					print_string_reg(1,11) <=  x"4" & (register_val(4)(3 downto 0) - 9);
				else
					print_string_reg(1,11) <=  x"3" & register_val(4)(3 downto 0);
				end if;
				
				if register_val(5)(7 downto 4) > 9 then
					print_string_reg(1,16) <=  x"4" & (register_val(5)(7 downto 4) - 9);
				else
					print_string_reg(1,16) <=  x"3" & register_val(5)(7 downto 4);
				end if;
				if register_val(5)(3 downto 0) > 9 then
					print_string_reg(1,17) <=  x"4" & (register_val(5)(3 downto 0) - 9);
				else
					print_string_reg(1,17) <=  x"3" & register_val(5)(3 downto 0);
				end if;
				
				if register_val(6)(7 downto 4) > 9 then
					print_string_reg(2,4) <=  x"4" & (register_val(6)(7 downto 4) - 9);
				else
					print_string_reg(2,4) <=  x"3" & register_val(6)(7 downto 4);
				end if;
				if register_val(6)(3 downto 0) > 9 then
					print_string_reg(2,5) <=  x"4" & (register_val(6)(3 downto 0) - 9);
				else
					print_string_reg(2,5) <=  x"3" & register_val(6)(3 downto 0);
				end if;
				
				if register_val(7)(7 downto 4) > 9 then
					print_string_reg(2,10) <=  x"4" & (register_val(7)(7 downto 4) - 9);
				else
					print_string_reg(2,10) <=  x"3" & register_val(7)(7 downto 4);
				end if;
				if register_val(7)(3 downto 0) > 9 then
					print_string_reg(2,11) <=  x"4" & (register_val(7)(3 downto 0) - 9);
				else
					print_string_reg(2,11) <=  x"3" & register_val(7)(3 downto 0);
				end if;				
---------------------- ACC, B, IP, PSW---------------------------------------------------------------------
				if lcd_data_alu(55 downto 52) > 9 then
					print_string_reg(2,17) <=  x"4" & (lcd_data_alu(55 downto 52) - 9);
				else
					print_string_reg(2,17) <=  x"3" & lcd_data_alu(55 downto 52);
				end if;
				if lcd_data_alu(51 downto 48) > 9 then
					print_string_reg(2,18) <=  x"4" & (lcd_data_alu(51 downto 48) - 9);
				else
					print_string_reg(2,18) <=  x"3" & lcd_data_alu(51 downto 48);
				end if;
				
				if lcd_data_alu(47 downto 44) > 9 then
					print_string_reg(3,4) <=  x"4" & (lcd_data_alu(47 downto 44) - 9);
				else
					print_string_reg(3,4) <=  x"3" & lcd_data_alu(47 downto 44);
				end if;
				if lcd_data_alu(43 downto 40) > 9 then
					print_string_reg(3,5) <=  x"4" & (lcd_data_alu(43 downto 40) - 9);
				else
					print_string_reg(3,5) <=  x"3" & lcd_data_alu(43 downto 40);
				end if;
				
				if lcd_data_alu(31 downto 28) > 9 then
					print_string_reg(3,10) <=  x"4" & (lcd_data_alu(31 downto 28) - 9);
				else
					print_string_reg(3,10) <=  x"3" & lcd_data_alu(31 downto 28);
				end if;
				if lcd_data_alu(27 downto 24) > 9 then
					print_string_reg(3,11) <=  x"4" & (lcd_data_alu(27 downto 24) - 9);
				else
					print_string_reg(3,11) <=  x"3" & lcd_data_alu(27 downto 24);
				end if;
				
				if lcd_data_alu(39 downto 36) > 9 then
					print_string_reg(3,17) <=  x"4" & (lcd_data_alu(39 downto 36) - 9);
				else
					print_string_reg(3,17) <=  x"3" & lcd_data_alu(39 downto 36);
				end if;
				if lcd_data_alu(35 downto 32) > 9 then
					print_string_reg(3,18) <=  x"4" & (lcd_data_alu(35 downto 32) - 9);
				else
					print_string_reg(3,18) <=  x"3" & lcd_data_alu(35 downto 32);
				end if;				
-----------------------------page 2---------------------------------------------------------------------------	
---------------------------------------------------SP, DPH, DPL-----------------------------------------------	
				if lcd_data_alu(23 downto 20) > 9 then
					print_string_reg_2(0,3) <=  x"4" & (lcd_data_alu(23 downto 20) - 9);
				else
					print_string_reg_2(0,3) <=  x"3" & lcd_data_alu(23 downto 20);
				end if;
				if lcd_data_alu(19 downto 16) > 9 then
					print_string_reg_2(0,4) <=  x"4" & (lcd_data_alu(19 downto 16) - 9);
				else
					print_string_reg_2(0,4) <=  x"3" & lcd_data_alu(19 downto 16);
				end if;
				
				if lcd_data_alu(15 downto 12) > 9 then
					print_string_reg_2(0,10) <=  x"4" & (lcd_data_alu(15 downto 12) - 9);
				else
					print_string_reg_2(0,10) <=  x"3" & lcd_data_alu(15 downto 12);
				end if;
				if lcd_data_alu(11 downto 8) > 9 then
					print_string_reg_2(0,11) <=  x"4" & (lcd_data_alu(11 downto 8) - 9);
				else
					print_string_reg_2(0,11) <=  x"3" & lcd_data_alu(11 downto 8);
				end if;
				
				if lcd_data_alu(7 downto 4) > 9 then
					print_string_reg_2(0,17) <=  x"4" & (lcd_data_alu(7 downto 4) - 9);
				else
					print_string_reg_2(0,17) <=  x"3" & lcd_data_alu(7 downto 4);
				end if;
				if lcd_data_alu(3 downto 0) > 9 then
					print_string_reg_2(0,18) <=  x"4" & (lcd_data_alu(3 downto 0) - 9);
				else
					print_string_reg_2(0,18) <=  x"3" & lcd_data_alu(3 downto 0);
				end if;
------------------------------------PCON, IE---------------------------------------------------------------				
				if lcd_data_pcon_tcon_ie(23 downto 20) > 9 then
					print_string_reg_2(1,5) <=  x"4" & (lcd_data_pcon_tcon_ie(23 downto 20) - 9);
				else
					print_string_reg_2(1,5) <=  x"3" & lcd_data_pcon_tcon_ie(23 downto 20);
				end if;
				if lcd_data_pcon_tcon_ie(19 downto 16) > 9 then
					print_string_reg_2(1,6) <=  x"4" & (lcd_data_pcon_tcon_ie(19 downto 16) - 9);
				else
					print_string_reg_2(1,6) <=  x"3" & lcd_data_pcon_tcon_ie(19 downto 16);
				end if;
				
				if lcd_data_pcon_tcon_ie(7 downto 4) > 9 then
					print_string_reg_2(1,11) <=  x"4" & (lcd_data_pcon_tcon_ie(7 downto 4) - 9);
				else
					print_string_reg_2(1,11) <=  x"3" & lcd_data_pcon_tcon_ie(7 downto 4);
				end if;
				if lcd_data_pcon_tcon_ie(3 downto 0) > 9 then
					print_string_reg_2(1,12) <=  x"4" & (lcd_data_pcon_tcon_ie(3 downto 0) - 9);
				else
					print_string_reg_2(1,12) <=  x"3" & lcd_data_pcon_tcon_ie(3 downto 0);
				end if;
----------------------------------TCON, P0, P1--------------------------------------------------------------				
				if lcd_data_pcon_tcon_ie(15 downto 12) > 9 then
					print_string_reg_2(2,5) <=  x"4" & (lcd_data_pcon_tcon_ie(15 downto 12) - 9);
				else
					print_string_reg_2(2,5) <=  x"3" & lcd_data_pcon_tcon_ie(15 downto 12);
				end if;
				if lcd_data_pcon_tcon_ie(11 downto 8) > 9 then
					print_string_reg_2(2,6) <=  x"4" & (lcd_data_pcon_tcon_ie(11 downto 8) - 9);
				else
					print_string_reg_2(2,6) <=  x"3" & lcd_data_pcon_tcon_ie(11 downto 8);
				end if;				
				
				if lcd_data_p0(7 downto 4) > 9 then
					print_string_reg_2(2,11) <=  x"4" & (lcd_data_p0(7 downto 4) - 9);
				else
					print_string_reg_2(2,11) <=  x"3" & lcd_data_p0(7 downto 4);
				end if;
				if lcd_data_p0(3 downto 0) > 9 then
					print_string_reg_2(2,12) <=  x"4" & (lcd_data_p0(3 downto 0) - 9);
				else
					print_string_reg_2(2,12) <=  x"3" & lcd_data_p0(3 downto 0);
				end if;
				
				if lcd_data_p1(7 downto 4) > 9 then
					print_string_reg_2(2,17) <=  x"4" & (lcd_data_p1(7 downto 4) - 9);
				else
					print_string_reg_2(2,17) <=  x"3" & lcd_data_p1(7 downto 4);
				end if;
				if lcd_data_p1(3 downto 0) > 9 then
					print_string_reg_2(2,18) <=  x"4" & (lcd_data_p1(3 downto 0) - 9);
				else
					print_string_reg_2(2,18) <=  x"3" & lcd_data_p1(3 downto 0);
				end if;		
----------------------------------TMOD, P2, P3--------------------------------------------------------------	
				if lcd_data_timer(7 downto 4) > 9 then
					print_string_reg_2(3,5) <=  x"4" & (lcd_data_timer(7 downto 4) - 9);
				else
					print_string_reg_2(3,5) <=  x"3" & lcd_data_timer(7 downto 4);
				end if;
				if lcd_data_timer(3 downto 0) > 9 then
					print_string_reg_2(3,6) <=  x"4" & (lcd_data_timer(3 downto 0) - 9);
				else
					print_string_reg_2(3,6) <=  x"3" & lcd_data_timer(3 downto 0);
				end if;
				
				if lcd_data_p2(7 downto 4) > 9 then
					print_string_reg_2(3,11) <=  x"4" & (lcd_data_p2(7 downto 4) - 9);
				else
					print_string_reg_2(3,11) <=  x"3" & lcd_data_p2(7 downto 4);
				end if;
				if lcd_data_p2(3 downto 0) > 9 then
					print_string_reg_2(3,12) <=  x"4" & (lcd_data_p2(3 downto 0) - 9);
				else
					print_string_reg_2(3,12) <=  x"3" & lcd_data_p2(3 downto 0);
				end if;
				
				if lcd_data_p3(7 downto 4) > 9 then
					print_string_reg_2(3,17) <=  x"4" & (lcd_data_p3(7 downto 4) - 9);
				else
					print_string_reg_2(3,17) <=  x"3" & lcd_data_p3(7 downto 4);
				end if;
				if lcd_data_p3(3 downto 0) > 9 then
					print_string_reg_2(3,18) <=  x"4" & (lcd_data_p3(3 downto 0) - 9);
				else
					print_string_reg_2(3,18) <=  x"3" & lcd_data_p3(3 downto 0);
				end if;				
--------------------------------page 3-----------------------------------------------------------------------	
-----------------------------------------------SBUF, SCON----------------------------------------------------
				if lcd_data_uart(7 downto 4) > 9 then
					print_string_reg_3(0,5) <=  x"4" & (lcd_data_uart(7 downto 4) - 9);
				else
					print_string_reg_3(0,5) <=  x"3" & lcd_data_uart(7 downto 4);
				end if;
				if lcd_data_uart(3 downto 0) > 9 then
					print_string_reg_3(0,6) <=  x"4" & (lcd_data_uart(3 downto 0) - 9);
				else
					print_string_reg_3(0,6) <=  x"3" & lcd_data_uart(3 downto 0);
				end if;	
				
				if lcd_data_uart(15 downto 12) > 9 then
					print_string_reg_3(0,13) <=  x"4" & (lcd_data_uart(15 downto 12) - 9);
				else
					print_string_reg_3(0,13) <=  x"3" & lcd_data_uart(15 downto 12);
				end if;
				if lcd_data_uart(11 downto 8) > 9 then
					print_string_reg_3(0,14) <=  x"4" & (lcd_data_uart(11 downto 8) - 9);
				else
					print_string_reg_3(0,14) <=  x"3" & lcd_data_uart(11 downto 8);
				end if;
-------------------------------------------TH1, TL1-----------------------------------------------------------	
				if lcd_data_timer(23 downto 20) > 9 then
					print_string_reg_3(1,4) <=  x"4" & (lcd_data_timer(23 downto 20) - 9);
				else
					print_string_reg_3(1,4) <=  x"3" & lcd_data_timer(23 downto 20);
				end if;
				if lcd_data_timer(19 downto 16) > 9 then
					print_string_reg_3(1,5) <=  x"4" & (lcd_data_timer(19 downto 16) - 9);
				else
					print_string_reg_3(1,5) <=  x"3" & lcd_data_timer(19 downto 16);
				end if;

				if lcd_data_timer(15 downto 12) > 9 then
					print_string_reg_3(1,11) <=  x"4" & (lcd_data_timer(15 downto 12) - 9);
				else
					print_string_reg_3(1,11) <=  x"3" & lcd_data_timer(15 downto 12);
				end if;
				if lcd_data_timer(11 downto 8) > 9 then
					print_string_reg_3(1,12) <=  x"4" & (lcd_data_timer(11 downto 8) - 9);
				else
					print_string_reg_3(1,12) <=  x"3" & lcd_data_timer(11 downto 8);
				end if;				
-------------------------------------------TH0, TL0-----------------------------------------------------------
				if lcd_data_timer(39 downto 36) > 9 then
					print_string_reg_3(2,4) <=  x"4" & (lcd_data_timer(39 downto 36) - 9);
				else
					print_string_reg_3(2,4) <=  x"3" & lcd_data_timer(39 downto 36);
				end if;
				if lcd_data_timer(35 downto 32) > 9 then
					print_string_reg_3(2,5) <=  x"4" & (lcd_data_timer(35 downto 32) - 9);
				else
					print_string_reg_3(2,5) <=  x"3" & lcd_data_timer(35 downto 32);
				end if;
				
				if lcd_data_timer(31 downto 28) > 9 then
					print_string_reg_3(2,11) <=  x"4" & (lcd_data_timer(31 downto 28) - 9);
				else
					print_string_reg_3(2,11) <=  x"3" & lcd_data_timer(31 downto 28);
				end if;
				if lcd_data_timer(27 downto 24) > 9 then
					print_string_reg_3(2,12) <=  x"4" & (lcd_data_timer(27 downto 24) - 9);
				else
					print_string_reg_3(2,12) <=  x"3" & lcd_data_timer(27 downto 24);
				end if;					
		end if;		
	end process;


process(clk)
		variable count_100ms : integer := 400;
		variable line_num, column_num : integer := 0;
		variable page_num : integer := 1;
		variable dm_page_num : dm_page_type_range := 1;	
		variable pm_page_num : pm_page_type_range := 1;		
		variable dm_index : dm_index_range := 0;		
		variable pm_index : pm_index_range := 0;		
		variable index_val : std_logic_vector(11 downto 0);
		variable msb, lsb : std_logic_vector(3 downto 0);
		variable temp_calc : integer;
	begin
	if (rising_edge(clk)) then
		case state is
			when pw_on =>
				lcd_en <= '0';
				lcd_rw <= '0';
				lcd_rs <= '0';
				count_100ms := count_100ms - 1;
				if count_100ms = 0 then
					state <= pw_on_2;
					count_100ms := 400;
				end if;	
			when pw_on_2 =>
				lcd_en <= '1';
				count_100ms := count_100ms - 1;
				if count_100ms = 0 then
					state <= fn_set;
					count_100ms := 200;
				end if;
			when fn_set =>		
				lcd_data <= x"3A";	
				state <= wait_100ms;
				next_state <= extended_fn_set;			
			when extended_fn_set =>
				lcd_en <= '1';			
				lcd_data <= x"09";
				state <= wait_100ms;
				next_state <= entry_mode_set;					
			when entry_mode_set =>
				lcd_en <= '1';				
				lcd_data <= x"06";
				state <= wait_100ms;
				next_state <= bias_set;			
			when bias_set =>
				lcd_en <= '1';			
				lcd_data <= x"1E";
				state <= wait_100ms;
				next_state <= fn_set_2;				
			when fn_set_2 =>
				lcd_en <= '1';			
				lcd_data <= x"39";
				state <= wait_100ms;
				next_state <= int_osc;
			when int_osc =>
				lcd_en <= '1';			
				lcd_data <= x"1B";
				state <= wait_100ms;
				next_state <= follower_ctrl;			
			when follower_ctrl =>
				lcd_en <= '1';			
				lcd_data <= x"6E";
				state <= wait_100ms;
				next_state <= power_ctrl;				
			when power_ctrl =>
				lcd_en <= '1';				
				lcd_data <= x"57";
				state <= wait_100ms;
				next_state <= contrast_set;				
			when contrast_set =>
				lcd_en <= '1';				
				lcd_data <= x"72";
				state <= wait_100ms;
				next_state <= fn_set_3;				
			when fn_set_3 =>
				lcd_en <= '1';			
				lcd_data <= x"38";
				state <= wait_100ms;
				next_state <= display_on;				
			when display_on =>
				lcd_en <= '1';			
				lcd_data <= x"0F";
				state <= wait_100ms;
				next_state <= home_command;	
			when home_command =>
                    lcd_en <= '1';    
                    lcd_rs <= '0';        
                    lcd_data <= x"80";
                    state <= wait_100ms;
                    next_state <= hold;    					
			when wait_100ms =>
				count_100ms := count_100ms - 1;
				if count_100ms = 0 then
					state <= wait_100ms_2;
					count_100ms := 50;
				end if;
			when wait_100ms_2 =>
				lcd_en <= '0';
				count_100ms := count_100ms - 1;
				if count_100ms = 0 then
					state <= next_state;
					count_100ms := 50;
				end if;
			when display_data =>
				fn_sw_last <= fn_sw;
				lcd_rs <= '1';
				lcd_en <= '1';
				if fn_sw = "10" then
				    if fn_sw_last /= "10" and fn_sw = "10" then
						lcd_rs <= '0';
						lcd_en <= '1';	
                        state <= home_command;
						line_num := 0;
						column_num := 0;
					else
						if page_num = 1 then
							lcd_data <= print_string_reg(line_num, column_num);
						elsif page_num = 2 then
							lcd_data <= print_string_reg_2(line_num, column_num);
						else
							lcd_data <= print_string_reg_3(line_num, column_num);
						end if;
						state <= load_data;
						column_num := column_num + 1;					

						if column_num = 20 then 
							column_num := 0;
							line_num := line_num + 1;
							if line_num = 4 then
								line_num := 0;
							end if;
						end if;	
							up_last <= up;
						if up_last = '1' and up = '0' then
							if page_num > 1 then
								page_num := page_num - 1;
								line_num := 0;
								column_num := 0;
								state <= home_command;
							end if;
						end if;
							down_last <= down;
						if down_last = '1' and down = '0' then
							if page_num < 3 then
								page_num := page_num + 1;
								line_num := 0;
								column_num := 0;
								state <= home_command;
							end if;
						end if;
					end if;
				elsif fn_sw = "11" then	
                    if fn_sw_last /= "11" and fn_sw = "11" then
						lcd_rs <= '0';
						lcd_en <= '1';	
                        state <= home_command;
                        dm_column <= 1;
						dm_index := (dm_page_num - 1) * 24;
                    else
						lcd_rs <= '1';
						lcd_en <= '1';	
					case dm_column is
						when 1 =>
						    if dm_index >= 128 then
                                lcd_data <=  x"20";
                            else
                                index_val := conv_std_logic_vector(dm_index, 12);
                                msb := index_val(7 downto 4);
                                if msb > 9 then
                                    lcd_data <=  x"4" & (msb - 9);
                                else
                                    lcd_data <=  x"3" & msb;
                                end if;
                            end if;
							dm_column <= dm_column + 1;
						when 2 => 
						    if dm_index >= 128 then
                                lcd_data <=  x"20";
                            else
                                index_val := conv_std_logic_vector(dm_index, 12);
                                lsb := index_val(3 downto 0);
                                if lsb > 9 then
                                    lcd_data <=  x"4" & (lsb - 9);
                                else
                                    lcd_data <=  x"3" & lsb;
                                end if;
                            end if;
							dm_column <= dm_column + 1;
						when 3 =>
						    if dm_index >= 128 then
                                lcd_data <=  x"20";
                            else
							    lcd_data <= x"3A";
							end if;
							dm_column <= dm_column + 1;
						when 4 | 7 | 10 | 13 | 16 | 19 =>
							if dm_index >= 128 then
								lcd_data <=  x"20";
							else
								msb := IRAMA(dm_index)(7 downto 4);
								if msb > 9 then
									lcd_data <=  x"4" & (msb - 9);
								else
									lcd_data <=  x"3" & msb;
								end if;
							end if;
							dm_column <= dm_column + 1;
						when 5 | 8 | 11 | 14 | 17 | 20 =>
							if dm_index >= 128 then
								lcd_data <=  x"20";
							else
								lsb := IRAMA(dm_index)(3 downto 0);
								if lsb > 9 then
									lcd_data <=  x"4" & (lsb - 9);
								else
									lcd_data <=  x"3" & lsb;
								end if;
							end if;
							if dm_column = 20 then 
								dm_column <= 1;
							else
								dm_column <= dm_column + 1;
							end if;
							dm_index := dm_index + 1;
							if dm_index rem 24 = 0 then
								dm_index := dm_index - 24;
							end if;
						when 6 | 9 | 12| 15 | 18 =>
							lcd_data <= x"20";
							dm_column <= dm_column + 1;
					end case;
					state <= load_data;

					up_last <= up;
					down_last <= down;
					if ((down_last = '1' and down = '0') or (up_last = '1' and up = '0')) then
						if down_last = '1' and down = '0' then 
							if dm_page_num < 6 then
								dm_page_num := dm_page_num + 1;
								dm_index := (dm_page_num - 1) * 24;
							else
								dm_page_num := 1;
								dm_index := 0;
							end if;
							state <= home_command;
							lcd_rs <= '0';
							lcd_en <= '1';
							dm_column <= 1; 
						else
							if dm_page_num > 1 then
								dm_page_num := dm_page_num - 1;
								dm_index := (dm_page_num - 1) * 24;
							else
								dm_page_num := 6;
								dm_index := 120;
							end if;
							state <= home_command;
							lcd_rs <= '0';
							lcd_en <= '1';
							dm_column <= 1;
						end if;
					end if;	
					end if;
				elsif fn_sw = "01" then
                    if fn_sw_last /= "01" and fn_sw = "01" then
						lcd_rs <= '0';
						lcd_en <= '1';
                        state <= home_command;
                        pm_column <= 1;
                        if pm_page_num <= 11 then
						  pm_index := (pm_page_num - 1) * 24;
						else
						  pm_index := 256 + (pm_page_num - 12) * 20;
						end if;
					else
					if pm_page_num <= 11 then 		
						case pm_column is
							when 1 =>
							    if pm_index >= 256 then
                                    lcd_data <=  x"2E";
                                else
                                    index_val := conv_std_logic_vector(pm_index, 12);
                                    msb := index_val(7 downto 4);
                                    if msb > 9 then
                                        lcd_data <=  x"4" & (msb - 9);
                                    else
                                        lcd_data <=  x"3" & msb;
                                    end if;
                                end if;
								pm_column <= pm_column + 1;
							when 2 => 
							    if pm_index >= 256 then
                                    lcd_data <=  x"2E";
                                else
                                    index_val := conv_std_logic_vector(pm_index, 12);
                                    lsb := index_val(3 downto 0);
                                    if lsb > 9 then
                                        lcd_data <=  x"4" & (lsb - 9);
                                    else
                                        lcd_data <=  x"3" & lsb;
                                    end if;
                                end if;
								pm_column <= pm_column + 1;
							when 3 =>
							    if pm_index >= 256 then
                                    lcd_data <=  x"2E";
                                else
								    lcd_data <= x"3A";
								end if;
								pm_column <= pm_column + 1;
							when 4 | 7 | 10 | 13 | 16 | 19 =>
								if pm_index >= 256 then
									lcd_data <=  x"2E";
								else
									msb := opcode(pm_index)(7 downto 4);
									if msb > 9 then
										lcd_data <=  x"4" & (msb - 9);
									else
										lcd_data <=  x"3" & msb;
									end if;
								end if;
								pm_column <= pm_column + 1;
							when 5 | 8 | 11 | 14 | 17 | 20 =>
								if pm_index >= 256 and pm_index <= 263 then
									lcd_data <=  x"2E";
								else
									lsb := opcode(pm_index)(3 downto 0);
									if lsb > 9 then
										lcd_data <=  x"4" & (lsb - 9);
									else
										lcd_data <=  x"3" & lsb;
									end if;
								end if;
								if pm_column = 20 then
									pm_column <= 1;
								else
									pm_column <= pm_column + 1;
								end if;
								pm_index := pm_index + 1;
								if pm_index rem 24 = 0 then
									pm_index := pm_index - 24;
								end if;
							when 6 | 9 | 12| 15 | 18 =>
								lcd_data <= x"20";
								pm_column <= pm_column + 1;
						end case;
					end if;
					
					if pm_page_num >= 12 then 		
						case pm_column is
							when 1 =>
                                if pm_index >= 2048 then
                                    lcd_data <=  x"20";
                                else							    
                                    index_val := conv_std_logic_vector(pm_index, 12);
                                    msb := index_val(11 downto 8);
                                    if msb > 9 then
                                        lcd_data <=  x"4" & (msb - 9);
                                    else
                                        lcd_data <=  x"3" & msb;
                                    end if;
                                end if;
								pm_column <= pm_column + 1;
							when 2 => 
							    if pm_index >= 2048 then
                                    lcd_data <=  x"20";
                                else
                                    index_val := conv_std_logic_vector(pm_index, 12);
                                    lsb := index_val(7 downto 4);
                                    if lsb > 9 then
                                        lcd_data <=  x"4" & (lsb - 9);
                                    else
                                        lcd_data <=  x"3" & lsb;
                                    end if;
                                end if;
								pm_column <= pm_column + 1;
							when 3 => 
							    if pm_index >= 2048 then
                                    lcd_data <=  x"20";
                                else
                                    index_val := conv_std_logic_vector(pm_index, 12);
                                    lsb := index_val(3 downto 0);
                                    if lsb > 9 then
                                        lcd_data <=  x"4" & (lsb - 9);
                                    else
                                        lcd_data <=  x"3" & lsb;
                                    end if;
                                end if;
								pm_column <= pm_column + 1;
							when 4 =>
							    if pm_index >= 2048 then
                                    lcd_data <=  x"20";
                                else
                                    lcd_data <= x"3A";
                                end if;
                                pm_column <= pm_column + 1;
							when 6 | 9 | 12 | 15 | 18 =>
							    if pm_index >= 2048 then
                                    lcd_data <=  x"20";
                                else
                                    msb := opcode(pm_index)(7 downto 4);
                                    if msb > 9 then
                                        lcd_data <=  x"4" & (msb - 9);
                                    else
                                        lcd_data <=  x"3" & msb;
                                    end if;
                                end if;
								pm_column <= pm_column + 1;
							when 7 | 10 | 13 | 16 | 19 =>
							    if pm_index >= 2048 then
                                    lcd_data <=  x"20";
                                else
                                    lsb := opcode(pm_index)(3 downto 0);
                                    if lsb > 9 then
                                        lcd_data <=  x"4" & (lsb - 9);
                                    else
                                        lcd_data <=  x"3" & lsb;
                                    end if;
                                end if;
								if pm_column = 20 then
									pm_column <= 1;
								else
									pm_column <= pm_column + 1;
								end if;
								pm_index := pm_index + 1;
								temp_calc := pm_index - 16;
								if temp_calc rem 20 = 0 then									
									pm_index := pm_index - 20;							
								end if;
							when 5 | 8 | 11| 14 | 17 | 20 =>
								lcd_data <= x"20";
								if pm_column = 20 then
									pm_column <= 1;
								else
									pm_column <= pm_column + 1;
								end if;							
						end case;
					end if;
						state <= load_data;						
						down_last <= down;
						up_last <= up;
						if ((down_last = '1' and down = '0') or (up_last = '1' and up = '0')) then
							if down_last = '1' and down = '0' then 
								if pm_page_num < 101 then
									pm_page_num := pm_page_num + 1;
									if pm_page_num >= 12 then
										pm_index := 256 + (pm_page_num - 12) * 20;
									else
										pm_index := (pm_page_num - 1) * 24;
									end if;
								else
									pm_index := 0;
									pm_page_num := 1;
								end if;
								state <= home_command;
								lcd_rs <= '0';
								lcd_en <= '1';
								pm_column <= 1;
							else
								if pm_page_num > 1 then
									pm_page_num := pm_page_num - 1;
									if pm_page_num >= 12 then
										pm_index := 256 + (pm_page_num - 12) * 20;
									else
										pm_index := (pm_page_num - 1) * 24;
									end if;
								else
									pm_page_num := 101;
									pm_index := 2036;
								end if;
								state <= home_command;
								lcd_rs <= '0';
								lcd_en <= '1';
								pm_column <= 1;
							end if;							
						end if;
					
						s100_last <= s100;
						if s100_last = '1' and s100 = '0' then
							if pm_page_num <= 11 then
								pm_page_num := 12;
								pm_index := 256;
							elsif pm_page_num >= 12 and pm_page_num <= 24 then
								pm_page_num := 25;
								pm_index := 516;
							elsif pm_page_num >= 25 and pm_page_num <= 37 then
								pm_page_num := 38;
								pm_index := 776;
							elsif pm_page_num >= 38 and pm_page_num <= 50 then
								pm_page_num := 51;
								pm_index := 1036;
							elsif pm_page_num >= 51 and pm_page_num <= 63 then
								pm_page_num := 64;
								pm_index := 1296;
							elsif pm_page_num >= 64 and pm_page_num <= 76 then
								pm_page_num := 77;
								pm_index := 1556;
							elsif pm_page_num >= 77 and pm_page_num <= 89 then
								pm_page_num := 90;
								pm_index := 1816;
							elsif pm_page_num >= 90 and pm_page_num <= 100 then
								pm_page_num := 101;
								pm_index := 2036;
							else
								pm_page_num := 1;
								pm_index := 0;
							end if;
							state <= home_command;
							lcd_rs <= '0';
							lcd_en <= '1';
							pm_column <= 1;
							if pm_page_num >= 12 then
								pm_index := 256 + (pm_page_num - 12) * 20;
							else
								pm_index := (pm_page_num - 1) * 24;
							end if;
						end if;
					end if;
				else
					null;
				end if;
			when load_data =>
				lcd_en <= '0';
				state <= hold;			
			when hold => 
					state <= display_data;		
			when others =>
				null;
		end case;
	end if;
	end process;

	process(Clk)
	variable up_range : integer;
	variable down_range : integer;
	begin
		if Clk'event and Clk = '1' then
			for i in 0 to 2047 loop
				up_range := i * 8 + 7;
				down_range := i * 8;
				opcode(i) <= lcd_data_opcode_in(up_range downto down_range);
			end loop;
		end if;
	end process;
	
	process(Clk)
	variable up_range : integer;
	variable down_range : integer;
	begin
		if Clk'event and Clk = '1' then
			for i in 0 to 127 loop
				up_range := i * 8 + 7;
				down_range := i * 8;
				IRAMA(i) <= lcd_data_ram_in(up_range downto down_range);
			end loop;
		end if;
	end process;
	
PSW_data <= lcd_data_alu(39 downto 32);

end Behavioral;
