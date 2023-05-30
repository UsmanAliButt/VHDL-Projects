--Dated 29 May 2023
--Author Usman Ali Butt
--Simple Uart TX implementation. Next phase to
--optimize it.

-- FSM implemenation States(start,transmit,stop)
-- Start: TX pin pulled low indicating begining of transmission
-- Transmit: Send 8 bit data and 1 stop bit
-- Stop: Tx pin pulled up indicating stop transmission

-- store : constant representing ASCII character 'U'
-- At Tx we are continuously transfering character 'U'
-- At serial consol of your PC you can verify 'U' printing infinitely.

-- Baud_clock : Uart clock extracted from main clock. We want 9600 bps
-- So divide main clock 12MHz/(9600*16). we want 1/16 clk. Each bit 
-- transfered every 16 baud clock. 

-- we can remove parameter 16 but then changes are required in code.
-- instead of 78 we then have 12M/9600 1250 which is equal to 78*16 1248

-- bit_clk : Original uart bits are send on this clock.    
 
library ieee;
use ieee.std_logic_1164.all;
 
entity uart is
	port( clk: in std_logic; --clock signal 12MHz  
		  tx: out std_logic  
		);
end uart;

architecture test of uart is
	signal bit_clk : std_logic;
	type states is (start,transmit,stop);
	signal state : states;
	constant store : std_logic_vector(7 downto 0) :=("01010101");
 begin	
 
	process(clk)
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
	
	process(bit_clk)
		variable i: integer:=0;
		variable j: integer:=0;
	begin
		if rising_edge(bit_clk) then
			if state = start then 
			i := i+1;
			-- After 8 baud clocks tx pulled low (start transmission) 
				if i = 8 then
					tx	<= '0';
					i := 0;
					state <= transmit;
				end if;	
			end if;
			
			if state = transmit then
			i := i+1;
			-- After 16 baud clocks start sending data LSB first
				if i = 16 then
				tx <= store(0);
				end if;
				
				if i = 32 then
				tx <= store(1);
				end if;
				
				if i = 48 then
				tx <= store(2);
				end if;
				
				if i = 64 then
				tx <= store(3);
				end if;
				
				if i = 80 then
				tx <= store(4);
				end if;
				
				if i = 96 then
				tx <= store(5);
				end if;
				
				if i = 112 then
				tx <= store(6);
				end if;
				
				if i = 128 then
				tx <= store(7);
				end if;
			-- After 144 baud clocks tx pull up (stop transmission)	
				if i = 144 then
				tx <= '1';
				end if;
				
				if i = 160 then
					state <= stop;
				end if;
			end if;	
			-- Remain in stop state for few time and then start again
			if state = stop then
				if j = 5 then
					j := 0;
					state <= stop;
				else
					i :=0;
					j := j+1;
					state <= start;
				end if;	
			end if;	
		end if;
	
	end process;
	
end test;