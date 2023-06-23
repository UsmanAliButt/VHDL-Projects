--Dated 23 June 2023
--Author Usman Ali Butt
--Simple Uart Rx implementation. Next phase to
--optimize it.

-- FSM implemenation States(idle,start)
-- Idle : Uart Rx line is waiting for start signal
-- Start: First falling edge of Rx line indicates 
-- incomming data. Switch the state to Start For
-- capturing 8 data bits and 1 stop bit.   

-- RX_Data(8 bit wide): Stores the received 8 data bits
-- leds   (5 bit wide): Output port to dispaly first 5 bits
-- of received character(ASCII) on default leds 

-- Baud_clock : Uart clock extracted from main clock. We want 9600 bps
-- Divide main clock 12MHz/(9600*16). we want 1/16 clk, or sampling rate 16.
-- Each bit captured from the middle. So first bit is located at bit clock 24.
-- First 16 bit clocks for start signal (falling edge) adding 8 bit clocks
-- lands us in middle of first data bit. 

-- we can remove parameter 16 but t hen changes are required in code.
-- instead of 78 we then have 12M/9600 1250 which is equal to 78*16 1248

-- bit_clk : Original uart bits are send on this clock.    
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity UartRX is
	 port( clk: in std_logic;   						-- clock signal 12MHz
		   leds : out std_logic_vector(0 to 4);			-- leds display LSB 0-4 of received char-ASCII  
		   rx: in std_logic
		 );		
end UartRX;


architecture test of UartRX is
	signal bit_clk : std_logic;                         -- uart clock
	type states is (idle,start);
	signal state : states :=idle ;
	signal RX_Data : std_logic_vector(7 downto 0);
 begin	
 
	process(clk) is
	variable baud_clock : integer range 0 to 78; -- For 9600 baud rate 12M/(9600*16)
	begin
		if rising_edge(clk) then
				if baud_clock = 78 then
					bit_clk <= '1';
					baud_clock:= 0;	
				else 
					bit_clk <= '0';
					baud_clock:= baud_clock + 1;
				end if;
		end if;
	end process;
	
	process(bit_clk) is
		variable i: integer:=0;
	begin	
		if rising_edge(bit_clk) then
	
			if state = idle then
				if rx <= '0' then			     -- rx falling edge 
					state <= start;              -- incoming data switch to start state
				end if;
			end if;
			
			if state = start then
			i:= i+1;
				if i = 24 then
				RX_Data(0) <= rx;				-- lsb	
				end if;
				
				if i = 40 then
				RX_Data(1) <= rx;				-- 2-bit	
				end if;
				
				if i = 56 then
				RX_Data(2) <= rx;				-- 3-bit	
				end if;
				
				if i = 72 then
				RX_Data(3) <= rx;				-- 4-bit	
				end if;
				
				if i = 88 then
				RX_Data(4) <= rx;				-- 5-bit	
				end if;
				
				if i = 104 then
				RX_Data(5) <= rx;				-- 6-bit	
				end if;
				
				if i = 120 then
				RX_Data(6) <= rx;				-- 7-bit	
				end if;
				
				if i = 136 then
				RX_Data(7) <= rx;				-- 8-bit	
				end if;
				
				if i = 152  then
				i:= 0;
					if rx = '1' then			-- Stop bit detected
						state <= idle;			-- Switch state to idle
					end if;					
				end if;	
				-- We can place 8 bit clocks delay before switching to idle
				-- I decided to leave it. No worries.
			end if;
			
		end if;
		
		leds <= RX_Data(4 downto 0);
		
	end process;
	
end architecture;