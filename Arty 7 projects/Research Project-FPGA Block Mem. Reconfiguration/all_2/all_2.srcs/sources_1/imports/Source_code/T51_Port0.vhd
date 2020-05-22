--
-- 8051 compatible microcontroller core
--
-- Version : 0300
--
-- Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
--           (c) 2004-2005 Andreas Voggeneder (andreas.voggeneder@fh-hagenberg.at)
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- Please report bugs to the author, but before you do so, please
-- make sure that this is not a derivative work and that
-- you have the latest version of this file.
--
-- The latest version of this file can be found at:
--	http://www.opencores.org/cvsweb.shtml/t51/
--
-- Limitations :
--	No pull-ups
--
-- File history :
--

library IEEE;
use IEEE.std_logic_1164.all;
--library unisim;
--use unisim.all;

entity T51_Port0 is
	generic(
		tristate  : integer := 1
	);
	port(
		Clk			  : in std_logic;
		Rst_n		  : in std_logic;
		Sel			  : in std_logic;
		Rd_RMW		: in std_logic;
		Wr			  : in std_logic;
		Data_In		: in std_logic_vector(7 downto 0);
		Data_Out	: out std_logic_vector(7 downto 0);
		IOPort : inout std_logic_vector(7 downto 0)
	);
end T51_Port0;

architecture rtl of T51_Port0 is 
	signal Port_Output	: std_logic_vector(7 downto 0);
	signal Port_Input	: std_logic_vector(7 downto 0);
	signal sel_line0  	: std_logic_vector(7 downto 0) := "00000000";

begin

	tristate_mux: if tristate/=0 generate
  	Data_Out <= Port_Input when Sel = '1' and Rd_RMW = '0' else (others =>'Z');
  	Data_Out <= Port_Output when Sel = '1' and Rd_RMW = '1' else (others =>'Z');
  end generate;
	
	std_mux: if tristate=0 generate
  	Data_Out <= Port_Input when Sel = '1' and Rd_RMW = '0' else 
  	            Port_Output when Sel = '1' and Rd_RMW = '1' else 
  	            (others =>'-');
  end generate;
  
process(Clk)
	begin
		if Clk'event and Clk = '1' then
			for i in 0 to 7 loop
				if sel_line0(i) = '0' then
					Port_Input(i) <= IOPort(i);
				else
					IOPort(i) <= 'Z';
					Port_Input(i) <= 'Z';
				end if;
				
				if sel_line0(i) = '1' then
					IOPort(i) <= Port_Output(i);
				else
					IOPort(i) <= 'Z';
				end if;
			end loop;
		end if;
	end process;

	process (Rst_n, Clk)
	variable onetime : std_logic := '0';
	begin
		if Rst_n = '0' then
			Port_Output <= (others =>'0');
		elsif Clk'event and Clk = '1' then
			if Wr = '1' then
				if onetime = '0' then
					sel_line0 <= Data_In;
					onetime := '1';
				else 
					Port_Output <= Data_In;
				end if;			
			end if;
		end if;
	end process;

end;
