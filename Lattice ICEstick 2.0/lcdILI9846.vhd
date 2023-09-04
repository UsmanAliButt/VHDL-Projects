-- Author: Usman Ali Butt	
-- Date: 4 August 2023
-- Graphical lcd interfaced with lattice ice40hx1k FPGA
-- Lcd controller ILI9486. Size 3.5 inch. pixel 320 x 480
-- Lcd few key parameters
-- Write strobe 50ns atleast - High 15ns Low 15ns atleast (datasheet says) 
-- Reset 5ms atleast before sending any new command (datasheet says)
-- 120ms after reset send sleep out commnad (datasheet says)

-- Optimization
-- LCD write data and command signals wr,cs,rs can be placed in another process 
-- called from main to writecommand and writedata
-- wrcommand and wrdata states can be made part of lcdstate. Commands counted in
-- wrcommand, given proper delay in single state.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;


entity lcd is
port ( clk    : in std_logic;                       --Clock 12MHz
       rd : out std_logic;                         	--Read control
       wr : out std_logic;                         	--Write control
       rs : out std_logic;                         	--Data or command control
	   cs : out std_logic;							--Chip select
	   reset	: out std_logic;					--reset lcd 
       data  	: out std_logic_vector(7 downto 0);	--Data line 8-bit parallel
	   leds		: out std_logic_vector(4 downto 0)  --leds for status can be removed	
	   );   
end lcd;


architecture Behavioral of lcd is 
-- lcd states
-- From idle go to initialize, comdat is to distinguish between initialization
-- command and its data bytes. Stobe is for wr going low to high (50 ns atleast).
-- After initialization lcddata state continously write data to gram. we no more need
-- to write commands.
type lcdstate is (idle, initialize, comdat, strobe, lcddata);
signal state : lcdstate;
 
-- lcd read write states
-- wrcommnd to write command and wrdata for data writing to lcd. delay is clock cycle delay b/w
-- high low of wr(write) signal. My clock is 83 ns and lcd wr requires 50 ns. I am over requirement but
-- still i need an extra clock delay (83*2 2 clock cycles for each H/L) between both high and low wr signal.
-- when initialization is done we only need to send data bytes to lcd. Colors state is that purpose.   
type lcdrw is (idle, wrcommand, wrdata, delay, colors);
signal rwstate : lcdrw ; 
 
-- lcd config array
-- First two bytes are commnads followed by number of data bytes and then original data bytes e.g 
-- X"00",X"C0",X"02",X"0d",X"0d"   
-- X"00",X"C0" is command  
-- X"02" total number of data bytes in command (here 2)
-- X"0d",X"0d" original data bytes
type lcdconfig is array (0 to 55) of std_logic_vector(7 downto 0); 
constant lcd_init : lcdconfig :=(
								X"00",X"01",X"00",					-- soft reset
								X"00",X"C0",X"02",X"0d",X"0d",		-- gama control
								X"00",X"C1",X"02",X"43",X"00",
								X"00",X"C2",X"01",X"00",			-- gama controle end
								X"00",X"3A",X"01",X"55", 			-- Color interface
								X"00",X"11",X"00",					-- sleep out
								X"00",X"13",X"00",		-- normal dispaly on
								X"00",X"20",X"00",		-- display inversion off
								X"00",X"29",X"00",		-- display on
								--X"00",X"2A",X"4",X"00",X"40",X"01",X"0f", --column address
								--X"00",X"2B",X"4",X"00",X"00",X"01",X"3f", --page addresss
								X"00",X"36",X"01",X"08",					-- memory access control
								X"00",X"B4",X"00",		
								X"00",X"B6",X"03",X"00",X"22",X"3B",		 
								X"00",X"C5",X"04",X"00",X"48",X"00",X"48",
								X"00",X"2C",X"00"							-- start writing to memory
								); 								

begin

process(clk)
	variable i : integer := 0;						-- Works with delay count(clock cycle delay count)
	variable j : integer range 0 to 55 := 0;		-- Works with data/commands(next data or command) 
	variable k : integer range 0 to 10 := 0;		-- Works with data bytes(next data byte of command) 
	variable count : integer range 0 to 60 := 0;	-- delay count (clock cycle delay)
	variable commandcount : integer range 0 to 2 := 0; 	-- always two command bytes
	variable datastrobe : integer range 0 to 2 := 0;	-- data strobe for proper high low timing
	variable lcd_colors : std_logic_vector(7 downto 0) := "00100101"; -- fixed color
	
begin
	if clk'event and clk = '1' then
		case state is
			when idle		=>
				rd 	<= '1';     			-- All controls high initially
				wr	<= '1';
				rs	<= '1';
				cs	<= '1';
				reset <= '1';
				count := 10;				-- 5ms delay for lcd power up(even less worked for me)
				state <= strobe;
			when initialize =>
					state 	<= comdat;
					rwstate <= wrcommand;
			when comdat		=>
				case rwstate is
					when wrcommand 	=>			-- fetch and write command
						wr	<= '0';
						rs	<= '0';
						cs	<= '0';
						count := 10;
						state <= strobe;
						k := 0;					-- k reset - Used to count number of data bytes of command
						data <= lcd_init(j);	-- command byte fetched from array
						leds	<= "10000";
					
					when wrdata		=>
						if k = to_integer(unsigned(lcd_init(j))) then
							if (j+k) >= lcd_init'LENGTH - 1  then  	-- if all initialization is done 
								state <= lcddata;  					-- jump to lcddata
							else	
								j:=j+k+1; 	 						-- indexing next command
								state 	<= initialize;   			-- Fetch next command
							end if;					
						else
							wr	<= '0';			-- fetch and write data
							rs	<= '1';
							cs	<= '0';
							count := 5;
							state <= strobe;
							k:=k+1;  				-- config data is placed on next iteration of j so j+k
							data <= lcd_init(j+k);  -- data byte fetched from array
							leds	<= "00001";
						end if;
					
					when idle		=>
					when delay 		=>				--So far useless in next phase will be utilized
				end case;
			when strobe		=>			
				if i = count then		-- count for clock delay purposes, depends of count value
					i := 0;				-- back to zero for next delay 
					wr	<= '1';			-- write goes high and data/command is writen in Gram
					leds	<= "00000";	
					
					case rwstate is
						when wrcommand 	=>							
							rwstate <= delay;  	-- After writing command byte give delay 
							j := j+1;  			-- next command indexed
							commandcount := commandcount + 1; -- command count increased
						when delay =>			-- Delay after strobing and next command data select
		
							if commandcount > 1 then -- Two command bytes before jumping to data bytes
								rwstate <= wrdata;
								commandcount := 0;
							else
								rwstate <= wrcommand;
							end if;	

							state   <= comdat;		-- command/data initialization
							
						when wrdata		=>
							rwstate <= delay;  -- After writing data give delay	
							commandcount := 2; -- No more commands by pass command check in dealy
						when idle		=>
							state <= initialize; -- From idle always go to initialize state
						when colors		=>
							if datastrobe > 1 then -- After strobing wr signal L to H give 1 clock cycle delay 
							datastrobe :=	0;	
							state <= lcddata;
							else
							--back to colors - proper delay to wr = '1' for high condition
							datastrobe := datastrobe + 1;
							end if;						
					end case;
					
				else
					i := i+1;		-- increment clock cycle count
				end if;
				
			when lcddata 	=>
							wr	<= '0';
							rs	<= '1';
							count := 4;  -- Four clock cycles dealy between H/L (83ns*4)
							data 		<= lcd_colors ;
							state 		<= strobe;
							rwstate   	<= colors;
							leds		<= "00100";							
		end case; --end main case
	
	end if;  -- end main if clock event
end process;

end Behavioral;
