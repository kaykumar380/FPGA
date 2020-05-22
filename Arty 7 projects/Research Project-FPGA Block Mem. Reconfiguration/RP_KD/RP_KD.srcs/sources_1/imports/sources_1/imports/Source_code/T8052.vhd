--
-- 8052 compatible microcontroller, with internal RAM & ROM
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
--
-- File history :
--

library IEEE;
use IEEE.std_logic_1164.all;
use work.T51_Pack.all;

entity T8052 is
	generic(
	  tristate          : integer := 0;
		ROMAddressWidth		: integer := 13;
		IRAMAddressWidth	: integer := 8);
	port(
		Clk_in			: in std_logic;
		P0		: inout  std_logic_vector(7 downto 0);
		P1		: inout  std_logic_vector(7 downto 0);
		P2	: inout std_logic_vector(7 downto 0);
		P3	: inout std_logic_vector(7 downto 0);
		INT0		: in std_logic;
		INT1		: in std_logic;
		T0			: in std_logic;
		T1			: in std_logic;
		T2			: in std_logic;
		T2EX		: in std_logic;
		RXD			: in std_logic;
		RXD_IsO		: out std_logic;
		RXD_O		: out std_logic;
		TXD			: out std_logic;
		red_led : out std_logic;
		active_h_led : out std_logic;
		step : in std_logic;
		start : in std_logic;
		reset_main : in std_logic; ----------------------------------------------------------RESET
		stop : in std_logic;
		lcd_en : out STD_LOGIC;
        lcd_rw : out STD_LOGIC;
        lcd_rs : out STD_LOGIC;
        lcd_data : out STD_LOGIC_VECTOR (7 downto 0);
        fn_sw : in STD_LOGIC_VECTOR (1 downto 0);
        up : in STD_LOGIC;
        down : in STD_LOGIC;
        s100 : in STD_LOGIC;
        --------------------------------------------------------------------------
        ser_in      : in  std_logic;                    -- serial data (rx line)
        sw_0        : in std_logic;
        sw_1        : in std_logic; -- start transmission
        ser_out     : out std_logic
        
        
	);
end T8052;

architecture rtl of T8052 is
   ------------------------------------------------------------------------
  component mode_sel is
     Port ( 
            clk: in std_logic;
            res : in std_logic;
            sw1 : in std_logic;
            sw0: in std_logic;
            mux_sel: out std_logic_vector (1 downto 0);
            core_res : out std_logic;
            data_ready: out std_logic;
            rom_read_en : out std_logic;
            clk_sel : out std_logic
     );
   end  component mode_sel;
   
   component clk_mux is
    Port ( 
          cor_clk : in std_logic;
          cons_clk: in std_logic;
          clk_sel : in std_logic;
          clk_out: out std_logic 
    
      );
   end component clk_mux;
   
   component mux_addrs is
        Port ( 
               sel: in std_logic_vector (1 downto 0);
               inp : in std_logic_vector(38 downto 0);
               mux_o: out std_logic_vector(12 downto 0)
               );
      end component mux_addrs;
   
   component receiver_1 is
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
   end component receiver_1;
   
   component transmitter_f is
     generic (
       g_CLKS_PER_BIT : integer := 10416     -- Needs to be set correctly
       );
     port (
       clk         : in  std_logic;
       res_n         : in  std_logic;
       data_ready  : in  std_logic; ---- start transmission
       i_TX_Byte   : in  std_logic_vector(7 downto 0);
       --active : out std_logic;
       ser_out : out std_logic;
       --done   : out std_logic;
       index  : out std_logic_vector(12 downto 0)
       --led    : out std_logic_vector(7 downto 0)
       );
   end component transmitter_f;
   
   
   -------------------------------------------------------------------------

    component lcd_controller
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
    end component;
	
	component ROM52
	  generic (
         rom_size : integer := 11    -- specify rom size in bits,e.g. 2**11=2028 Byte ROM 
        );
		port(
			Clk	: in std_logic;
			A	: in std_logic_vector(ROMAddressWidth - 1 downto 0);
			Din : in std_logic_vector(7 downto 0);
			progk : in std_logic;  
            read_now : in std_logic;
			D	: out std_logic_vector(7 downto 0)
			
		);
	end component;



  constant ext_mux_in_num : integer := 8; --63;
  type ext_mux_din_type is array(0 to ext_mux_in_num-1) of std_logic_vector(7 downto 0);
  subtype ext_mux_en_type  is std_logic_vector(0 to ext_mux_in_num-1);

	signal	Ready		             : std_logic;
	signal	ROM_Addr	           : std_logic_vector(15 downto 0);
	signal	ROM_Data	           : std_logic_vector(7 downto 0);
	signal	RAM_Addr,RAM_Addr_r  : std_logic_vector(15 downto 0);
	signal	RAM_RData	           : std_logic_vector(7 downto 0);
	signal	RAM_DO		           : std_logic_vector(7 downto 0);
	signal	RAM_WData	           : std_logic_vector(7 downto 0);
	signal	RAM_Rd		           : std_logic;
	signal	RAM_Wr		           : std_logic;
	signal	RAM_WE_n	           : std_logic;
  signal  ram_access           : std_logic;
  signal  ext_ram_en           : std_logic;
	signal	IO_Rd		             : std_logic;
	signal	IO_Wr		             : std_logic;
	signal	IO_Addr		           : std_logic_vector(6 downto 0);
	signal	IO_Addr_r	           : std_logic_vector(6 downto 0);
	signal	IO_WData	           : std_logic_vector(7 downto 0);
	signal	IO_RData	           : std_logic_vector(7 downto 0);
  signal  IO_RData_arr         : ext_mux_din_type;
  signal  IO_RData_en          : ext_mux_en_type;

	signal	P0_Sel		: std_logic;
	signal	P1_Sel		: std_logic;
	signal	P2_Sel		: std_logic;
	signal	P3_Sel		: std_logic;
	signal	TMOD_Sel	: std_logic;
	signal	TL0_Sel		: std_logic;
	signal	TL1_Sel		: std_logic;
	signal	TH0_Sel		: std_logic;
	signal	TH1_Sel		: std_logic;
	signal	T2CON_Sel	: std_logic;
	signal	RCAP2L_Sel	: std_logic;
	signal	RCAP2H_Sel	: std_logic;
	signal	TL2_Sel		: std_logic;
	signal	TH2_Sel		: std_logic;
	signal	SCON_Sel	: std_logic;
	signal	SBUF_Sel	: std_logic;

	signal	P0_Wr		: std_logic;
	signal	P1_Wr		: std_logic;
	signal	P2_Wr		: std_logic;
	signal	P3_Wr		: std_logic;
	signal	TMOD_Wr		: std_logic;
	signal	TL0_Wr		: std_logic;
	signal	TL1_Wr		: std_logic;
	signal	TH0_Wr		: std_logic;
	signal	TH1_Wr		: std_logic;
	signal	T2CON_Wr	: std_logic;
	signal	RCAP2L_Wr	: std_logic;
	signal	RCAP2H_Wr	: std_logic;
	signal	TL2_Wr		: std_logic;
	signal	TH2_Wr		: std_logic;
	signal	SCON_Wr		: std_logic;
	signal	SBUF_Wr		: std_logic;
	signal	s_Rst_n		: std_logic;
	signal	UseR2		: std_logic;
	signal	UseT2		: std_logic;
	signal	UART_Clk	: std_logic;
	signal	R0			: std_logic;
	signal	R1			: std_logic;
	signal	SMOD		: std_logic;

	signal	Int_Trig	: std_logic_vector(6 downto 0);
	signal	Int_Acc		: std_logic_vector(6 downto 0);

	signal	RI			: std_logic;
	signal	TI			: std_logic;
	signal	OF0			: std_logic;
	signal	OF1			: std_logic;
	signal	OF2			: std_logic;
	signal	clk : std_logic := '0';     -------------------rom clk
	
	signal step_last : std_logic := '1';
	signal s_step : std_logic := '0';
	signal s_start : std_logic := '0';
	signal s_stop : std_logic := '0';
	signal s_exe : std_logic := '0';
	signal slow_clk : std_logic := '0';
	signal db3, db2, db1 : std_logic := '1';
	signal s_step_db : std_logic := '0';
	signal s_step_db_last : std_logic := '0';	
	
	signal s_lcd_data_alu : std_logic_vector(55 downto 0);
	signal s_lcd_data_pcon_tcon_ie : std_logic_vector(23 downto 0);
	signal s_lcd_data_uart : std_logic_vector(15 downto 0);
	signal s_lcd_data_timer : std_logic_vector(39 downto 0);
	signal s_lcd_data_p0 : std_logic_vector(7 downto 0);
	signal s_lcd_data_p1 : std_logic_vector(7 downto 0);
	signal s_lcd_data_p2 : std_logic_vector(7 downto 0);
	signal s_lcd_data_p3 : std_logic_vector(7 downto 0);
	signal s_opcode_out : std_logic_vector(16383 downto 0);
	signal s_IRAMA_out : std_logic_vector(1023 downto 0);
	signal one_t_flag : std_logic := '1';
	signal core_clk : std_logic := '0';
	
	-------------------------------------------
	signal reset,data_ready,rom_read_en,clk_sel : std_logic;
	signal adrs_mux_sel : std_logic_vector(1 downto 0);
	
	signal rom_clk : std_logic;
	
	signal recv_index,trans_index,adrs_mux_out: std_logic_vector (12 downto 0);
     
    signal led: std_logic_vector (7 downto 0); 
    signal int_recv: std_logic;                 
	
	-------------------------------------------
	
begin

	Ready <= '1';	
  
  process (reset, clk)
  begin
    if reset = '0' or one_t_flag = '1' then
		IO_Addr_r    <= (others =>'0');
		RAM_Addr_r   <= (others =>'0');
		one_t_flag <= '0';
    elsif clk'event and clk = '1' then
        IO_Addr_r <= IO_Addr;
        if Ready = '1' then
			RAM_Addr_r  <= RAM_Addr;
		end if;
    end if;
  end process;
  
lcd : lcd_controller port map(
       clk => slow_clk,
       lcd_en => lcd_en,
       lcd_rw => lcd_rw,
       lcd_rs => lcd_rs,
       lcd_data => lcd_data,
       fn_sw => fn_sw,
       up => up,
       down => down,
       s100 => s100,
	   lcd_data_alu => s_lcd_data_alu,
	   lcd_data_pcon_tcon_ie => s_lcd_data_pcon_tcon_ie,
	   lcd_data_p0 => s_lcd_data_p0,
	   lcd_data_p1 => s_lcd_data_p1,
	   lcd_data_p2 => s_lcd_data_p2,
	   lcd_data_p3 => s_lcd_data_p3,
	   lcd_data_uart => s_lcd_data_uart,
	   lcd_data_timer => s_lcd_data_timer,
	   lcd_data_opcode_in => s_opcode_out,
	   lcd_data_ram_in => s_IRAMA_out
	   );
       
	rom : ROM52 
	  generic map (rom_size => 11)
	   port map(
			Clk => rom_clk,
			A => adrs_mux_out, ----ROM_Addr(ROMAddressWidth - 1 downto 0), ------kkkkkk
			D => ROM_Data,
			Din => led,                -------------------
            progk => rom_read_en,       ------------------
            read_now =>	int_recv		----------------------
			--opcode_out => s_opcode_out
			);

  ram_access <= '1' when (RAM_Rd or RAM_Wr)='1' else
                '0';

  -- xram bus access is pipelined.
  -- so use registered signal for selecting read data
	RAM_RData <= RAM_DO;
               
  -- select data mux             

  -- internal XRAM select signal is active low.
  -- so internal xram is selected when external XRAM is not selected (ext_ram_en = '0')

	core51 : T51
		generic map(
			DualBus         => 1,
      tristate        => tristate,
      t8032           => 0,
			RAMAddressWidth => IRAMAddressWidth)
		port map(
			Clk          => Clk,
			Rst_n        => s_Rst_n,
			Ready        => Ready,
			ROM_Addr     => ROM_Addr,
			ROM_Data     => ROM_Data,
			RAM_Addr     => RAM_Addr,
			RAM_RData    => RAM_RData,
			RAM_WData    => RAM_WData,
			RAM_Rd       => RAM_Rd,
			RAM_Wr       => RAM_Wr,
			Int_Trig     => Int_Trig,
			Int_Acc      => Int_Acc,
			SFR_Rd_RMW   => IO_Rd,
			SFR_Wr       => IO_Wr,
			SFR_Addr     => IO_Addr,
			SFR_WData    => IO_WData,
			SFR_RData_in => IO_RData,
			lcd_data_alu => s_lcd_data_alu,
			IRAMA_out => s_IRAMA_out);

	glue51 : T51_Glue
	  generic map(
        tristate   => tristate)
		port map(
		Clk        => Clk,
        Rst_n      => s_Rst_n,
        INT0       => INT0,
        INT1       => INT1,
        RI         => RI,
        TI         => TI,
        OF0        => OF0,
        OF1        => OF1,
        OF2        => OF2,
        IO_Wr      => IO_Wr,
        IO_Addr    => IO_Addr,
        IO_Addr_r  => IO_Addr_r,
        IO_WData   => IO_WData,
        IO_RData   => IO_RData_arr(0),
        Selected   => IO_RData_en(0),
        Int_Acc    => Int_Acc,
        R0         => R0,
        R1         => R1,
        SMOD       => SMOD,
        P0_Sel     => P0_Sel,
        P1_Sel     => P1_Sel,
        P2_Sel     => P2_Sel,
        P3_Sel     => P3_Sel,
        TMOD_Sel   => TMOD_Sel,
        TL0_Sel    => TL0_Sel,
        TL1_Sel    => TL1_Sel,
        TH0_Sel    => TH0_Sel,
        TH1_Sel    => TH1_Sel,
        T2CON_Sel  => T2CON_Sel,
        RCAP2L_Sel => RCAP2L_Sel,
        RCAP2H_Sel => RCAP2H_Sel,
        TL2_Sel    => TL2_Sel,
        TH2_Sel    => TH2_Sel,
        SCON_Sel   => SCON_Sel,
        SBUF_Sel   => SBUF_Sel,
        P0_Wr      => P0_Wr,
        P1_Wr      => P1_Wr,
        P2_Wr      => P2_Wr,
        P3_Wr      => P3_Wr,
        TMOD_Wr    => TMOD_Wr,
        TL0_Wr     => TL0_Wr,
        TL1_Wr     => TL1_Wr,
        TH0_Wr     => TH0_Wr,
        TH1_Wr     => TH1_Wr,
        T2CON_Wr   => T2CON_Wr,
        RCAP2L_Wr  => RCAP2L_Wr,
        RCAP2H_Wr  => RCAP2H_Wr,
        TL2_Wr     => TL2_Wr,
        TH2_Wr     => TH2_Wr,
        SCON_Wr    => SCON_Wr,
        SBUF_Wr    => SBUF_Wr,
        Int_Trig   => Int_Trig,
		lcd_data_pcon_tcon_ie => s_lcd_data_pcon_tcon_ie);

    tp0 : T51_Port0
      generic map(
        tristate   => tristate)
      port map(
        Clk        => Clk,
        Rst_n      => s_Rst_n,
        Sel        => P0_Sel,
        Rd_RMW     => IO_Rd,
        Wr         => P0_Wr,
        Data_In    => IO_WData,
        Data_Out   => IO_RData_arr(1),
        IOPort  => P0);

     IO_RData_en(1) <= P0_Sel;


    tp1 : T51_Port1
      generic map(
        tristate   => tristate)
      port map(
        Clk        => Clk,
        Rst_n      => s_Rst_n,
        Sel        => P1_Sel,
        Rd_RMW     => IO_Rd,
        Wr         => P1_Wr,
        Data_In    => IO_WData,
        Data_Out   => IO_RData_arr(2),
        IOPort  => P1);

    IO_RData_en(2) <= P1_Sel;
	
    tp2 : T51_Port2
      generic map(
        tristate   => tristate)
      port map(
        Clk        => Clk,
        Rst_n      => s_Rst_n,
        Sel        => P2_Sel,
        Rd_RMW     => IO_Rd,
        Wr         => P2_Wr,
        Data_In    => IO_WData,
        Data_Out   => IO_RData_arr(3),
        IOPort  => P2);

    IO_RData_en(3) <= P2_Sel;

	tp3 : T51_Port3
      generic map(
        tristate   => tristate)
      port map(
        Clk        => Clk,
        Rst_n      => s_Rst_n,
        Sel        => P3_Sel,
        Rd_RMW     => IO_Rd,
        Wr         => P3_Wr,
        Data_In    => IO_WData,
        Data_Out   => IO_RData_arr(4),
        IOPort  => P3);

    IO_RData_en(4) <= P3_Sel;


    tc01 : T51_TC01
      generic map(
        FastCount => 0,
        tristate  => tristate)
      port map(
        Clk      => Clk,
        Rst_n    => s_Rst_n,
        T0       => T0,
        T1       => T1,
        INT0     => INT0,
        INT1     => INT1,
        M_Sel    => TMOD_Sel,
        H0_Sel   => TH0_Sel,
        L0_Sel   => TL0_Sel,
        H1_Sel   => TH1_Sel,
        L1_Sel   => TL1_Sel,
        R0       => R0,
        R1       => R1,
        M_Wr     => TMOD_Wr,
        H0_Wr    => TH0_Wr,
        L0_Wr    => TL0_Wr,
        H1_Wr    => TH1_Wr,
        L1_Wr    => TL1_Wr,
        Data_In  => IO_WData,
        Data_Out => IO_RData_arr(5),
        OF0      => OF0,
        OF1      => OF1,
		lcd_data_timer => s_lcd_data_timer);

    IO_RData_en(5) <= TMOD_Sel or TH0_Sel or TL0_Sel or TH1_Sel or TL1_Sel;

    tc2 : T51_TC2
      generic map(
        FastCount => 0,
        tristate  => tristate)
      port map(
        Clk      => Clk,
        Rst_n    => s_Rst_n,
        T2       => T2,
        T2EX     => T2EX,
        C_Sel    => T2CON_Sel,
        CH_Sel   => RCAP2H_Sel,
        CL_Sel   => RCAP2L_Sel,
        H_Sel    => TH2_Sel,
        L_Sel    => TL2_Sel,
        C_Wr     => T2CON_Wr,
        CH_Wr    => RCAP2H_Wr,
        CL_Wr    => RCAP2L_Wr,
        H_Wr     => TH2_Wr,
        L_Wr     => TL2_Wr,
        Data_In  => IO_WData,
        Data_Out => IO_RData_arr(6),
        UseR2    => UseR2,
        UseT2    => UseT2,
        UART_Clk => UART_Clk,
        F        => OF2);

    IO_RData_en(6) <= T2CON_Sel or RCAP2H_Sel or RCAP2L_Sel or TH2_Sel or TL2_Sel;


    uart : T51_UART
      generic map(
        FastCount => 0,
        tristate  => tristate)
      port map(
        Clk      => Clk,
        Rst_n    => s_Rst_n,
        UseR2    => UseR2,
        UseT2    => UseT2,
        BaudC2   => UART_Clk,
        BaudC1   => OF1,
        SC_Sel   => SCON_Sel,
        SB_Sel   => SBUF_Sel,
        SC_Wr    => SCON_Wr,
        SB_Wr    => SBUF_Wr,
        SMOD     => SMOD,
        Data_In  => IO_WData,
        Data_Out => IO_RData_arr(7),
        RXD      => RXD,
        RXD_IsO  => RXD_IsO,
        RXD_O    => RXD_O,
        TXD      => TXD,
        RI       => RI,
        TI       => TI,
		lcd_data_uart => s_lcd_data_uart);
--------------------------------------------------------------------instantiation
mod_sel_ins : mode_sel 
     Port map (
            clk => Clk_in, 
            res => reset_main,
            sw1 => sw_1,
            sw0 => sw_0,
            mux_sel => adrs_mux_sel,
            core_res => reset,
            data_ready => data_ready,
            rom_read_en => rom_read_en,
            clk_sel => clk_sel
     );
 
clk_mux_ins: clk_mux
         Port map ( 
               cor_clk => Clk,
               cons_clk=> Clk_in,
               clk_sel => clk_sel,
               clk_out => rom_clk
         
           );   
           
mux_adrs_ins:  mux_addrs 
         Port map( 
                  sel => adrs_mux_sel,
                  inp (38 downto 26) => ROM_Addr(ROMAddressWidth - 1 downto 0),
                  inp (25 downto 13) => recv_index,
                  inp (12 downto 0) => trans_index,
                  mux_o => adrs_mux_out
                  );
        
              
recv_ins:  receiver_1
       generic map(
        count_per_bit => 10416    -- (100,000_000/9600 = 10416.6666)
       )  
           port map (
                      clk         => Clk_in,                 
                      res_n         => reset_main,                   
                      ser_in      => ser_in,
                      int_recv    => int_recv,
                      led         => led,
                      index       => recv_index
                  );
              
              
 trans_ins: transmitter_f 
         generic map(
        g_CLKS_PER_BIT => 10416)     -- Needs to be set correctly
              
         port map(
                  clk         => Clk_in,
                  res_n         => reset_main,
                  data_ready  => data_ready, 
                  i_TX_Byte   => ROM_data,
                  ser_out     => ser_out,
                  index       => trans_index
                  );
             
                           
     
-----------------------------------------------------------------		

    IO_RData_en(7) <= SCON_Sel or SBUF_Sel;
    
    tristate_mux: if tristate/=0 generate
      drive: for i in 0 to ext_mux_in_num-1 generate
        IO_RData <= IO_RData_arr(i);
      end generate;
    end generate;

	  std_mux: if tristate=0 generate
	    process(IO_RData_en,IO_RData_arr)
	    begin
	      IO_RData <= IO_RData_arr(0);
	      for i in 1 to ext_mux_in_num-1 loop
	        if IO_RData_en(i)='1' then
	          IO_RData <= IO_RData_arr(i);
	        end if;
	      end loop;
	    end process;
	  end generate;
	  
	  process(Clk_in)
	  variable counter : integer := 50000;
	  begin
	  if Clk_in'event and Clk_in = '1' then
	       counter := counter - 1;
	       if counter = 0 then
	           slow_clk <= not slow_clk;
	           counter := 50000;
	       end if;
	  end if;
	  end process;
	  
	  process(Clk_in)
	  variable counter : integer := 50000;
	  begin
	  if Clk_in'event and Clk_in = '1' then
	       counter := counter - 1;
	       if counter = 0 then
	           core_clk <= not core_clk;
	           counter := 50000;
	       end if;
	  end if;
	  end process;	  
	  
	  process(core_clk)
	  variable pulse_var : std_logic := '0';
	  variable pulse_counter : integer := 0;
	  begin
	  if core_clk'event and core_clk = '1' then
		db1 <= step;
		db2 <= db1;
		db3 <= db2;
		if (db3 = '0' and db2 = '0' and db1 = '0') then
			s_step_db <= '1';
		else
			s_step_db <= '0';
		end if;
		
		s_step_db_last <= s_step_db;
		if ((s_step_db_last = '0' and s_step_db = '1') or pulse_var = '1') and pulse_counter /= 2 then
			pulse_counter := pulse_counter + 1;
			pulse_var := '1';
			s_step <= '1';
		else
			s_step <= '0';
			if pulse_counter = 2 then
				pulse_counter := 0;
				pulse_var := '0';
			end if;
		end if;
                
      end if;
	  end process;
	  
	  process(core_clk)
	  variable keep_entry : std_logic := '0';
	  begin
	  if core_clk'event and core_clk = '1' then
	       if start = '0' or keep_entry = '1' then
	           s_start <= '1';
	           keep_entry := '1';
                if stop = '0' or step = '0' or reset = '0' then
                     keep_entry := '0';
                end if;	           
	       else
	           s_start <= '0';
	       end if;
	  end if;
	  end process;
	  
	  process(core_clk)
      variable keep_entry : std_logic := '0';
      begin
      if core_clk'event and core_clk = '1' then
           if stop = '0' or keep_entry = '1' then
               s_stop <= '1';
               keep_entry := '1';
               if start = '0' or step = '0' or reset = '0' then
                   keep_entry := '0';
               end if;                 
           else
               s_stop <= '0';             
           end if;
      end if;
      end process;
      	  
      process(core_clk)
      begin
      if core_clk'event and core_clk = '1' then
            s_exe <= (s_start or s_step) and not s_stop;
            if s_exe = '1' then
                Clk <= not Clk;
            end if;
      end if;
      end process;

	  red_led <= s_stop;
	  active_h_led <= s_start;
	  
	  s_lcd_data_p0 <= P0;
	  s_lcd_data_p1 <= P1;
	  s_lcd_data_p2 <= P2;
	  s_lcd_data_p3 <= P3;
	  
	  s_Rst_n <= '0' when (reset = '0' or one_t_flag = '1') else '1';
end;
