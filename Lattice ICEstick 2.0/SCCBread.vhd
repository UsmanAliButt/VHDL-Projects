-- Author 	: Usman Ali Butt
-- Dated 	: 11 August 2023 

-- Simple SCCB read cycle. SCCB is almost like I2C. ACK is considered dont care in SCCB.  
-- Below solution is just a simple how to configure SCCB slave with master. 
-- Solution can be optimized e.g.
---- Repeated code can be placed in a function and called every time when required.

-- Lattice ice40 FPGA is used, clock frequency is 12MHz, scaled down to 100KHz for 
-- SCCB.  

-- clk: input clock to FPGA
-- scl: SCCB clock. Its declared as inout can be only in. I declared inout to see if 
-- 		slave stretches the clock. So far no stretching.
-- sda: SCCB data line. Must be inout and in tristate (open drain). Since data travels
-- 		between master and slave. If master/slave is done sending, should not hold the bus
-- 		it must be floating when no one is sending data.   
-- leds: Leds to see status of what is read from slave register. 5 leds so LSB of 8-bit 
-- 		register is displayed on Leds.

-- 					SCCB has weird read cycle. 
-- First write cycle needs to be performed before read. Since write is the only cycle in which register
-- address can be specified. 
-----------------------------------------------------------------------------
--  |Start condition(sda high to low when scl is high) -> 					|
-- 	|	address of slave(7 bit) -> 											|
--	|		Write (0)  -> 													|
--	|			ACK (dont care) -> 											|
-- 	|				register address (8 bit) -> 							|
--	|					stop condition (sda low to high when scl is high) 	|
--  |Start condition(sda high to low when scl is high) -> 					|
-- 	|	address of slave(7 bit) -> 											|
--	|		read (1)  -> 													|
--	|			ACK (dont care) -> 											|
-- 	|				read register  (8 bit) -> 								|
--	|					stop condition (sda low to high when scl is high) 	|
-----------------------------------------------------------------------------
--

-- State machine 
--	idle			: Idle state both scl and sda are high
--	start			: Start of SCCB read/write cycle sda comes low when scl is high
--	addressW		: Slave address for writing 7-bit (8th bit is 0)
--	addressR		: Slave address for reading 7-bit (8th bit is 1)
--	midacknowledge	: dont care ACK bit. Comes between single SCCB cycle
--	acknowledge		: dont care ACK bit. Comes at the end of the single cycle
--	regW			: register address to write 8-bit
--	regR			: register address to read 8-bit
--	stopadjust		: single dutycycle delay to perfectly allign stop condition.
--	stop			: sda goes low to high in between of scl high. stopadjust alligns sda between scl high.


library ieee;
use ieee.std_logic_1164.all;

entity SCCBread is
	generic(
	    Clkfrequency	: integer := 12000000; -- 12 MHz
        I2cfrequency    : integer := 100000   -- 100 kHz		
	);
	port(
		clk: in std_logic;
		scl: inout std_logic;
		sda: inout std_logic;
		leds: out std_logic_vector(4 downto 0)
	);
end SCCBread;

architecture Behavioral of SCCBread is

-- I2c states in our case
type i2cstate is (idle, start, addressW, addressR, midacknowledge, acknowledge, regW, regR, stopadjust, stop);
signal state : i2cstate ;

-- Slave address 
-- LSF is SCCB RW bit, write=0 read=1 
-- MSF 7 bit slave address 
-- hex42 (01000010) is slave address of ov7670 for write
-- hex43 (01000011) is slave address of ov7670 for read
constant slaveaddressW : STD_LOGIC_VECTOR(7 downto 0) := "01000010";
constant slaveaddressR : STD_LOGIC_VECTOR(7 downto 0) := "01000011";
-- Reg 0x0A (00001010) PID of vendor. Must output 0x76
constant Regaddress	   : STD_LOGIC_VECTOR(7 downto 0) := "00001010";
signal   data 		   : STD_LOGIC_VECTOR(7 downto 0) ;


-- Cycles required for 100Khz frequency production 
constant Clkdivider	 : integer := Clkfrequency 	/ I2cfrequency; -- Full Scl period
constant Sclperiod   : integer := Clkdivider 	/ 2; 			-- Half of scl period 
constant sclmid      : integer := Sclperiod 	/ 2;  			-- Quater 1/4 of scl period 
signal 	 dat	  	 : std_logic;								-- holds sda value
signal 	 sct	  	 : std_logic;								-- holds scl value
signal 	 ReaWri	  	 : std_logic;								-- Read Write cycle control 
begin
		
	-- Process to produce 100KHz clock
	process(clk)
	variable counter 	: integer range 0 to Clkdivider; 		-- Full scl period 
	variable count		: integer range 0 to 8 := 8 ;			-- Control to send 8-bits( bit by bit )
	variable delay		: integer range 0 to 500 := 0 ; 		-- delay if required can be ommitted 
	variable sclactive 	: std_logic;							-- SCL line status, enable only during data transfer 
	variable tristateenable  	: STD_LOGIC;			        -- sda line tristate enable 
	variable tristateenablescl  : STD_LOGIC;                    -- scl line tristate enable (can be ommitted)
    begin
        if rising_edge(clk) then
            if counter 	<  Sclperiod then				-- counter less then half scl period enable scl high
                sct 	<= '1';
				if (counter =  sclmid) then             -- counter in mid of scl high start SCCB
					
					if state = idle then
						if delay = 50 then 	
							delay := 0;		
							
							if ReaWri = '1' then
								state <= addressR;
							else	
								state <= addressW;
							end if;
							
							dat <=	'0';
							sclactive		:='1';
							tristateenable	:='1';
							tristateenablescl := '1';
						end if;	
						count:=8;
						delay := delay + 1;
					end if;
					if state = stop then
						dat <=	'1';	
						state<= idle;
						sclactive:='0';
					end if;
				end  if;
            elsif counter 	< Clkdivider then           -- counter less than scl full period 
				if sclactive = '1' then					-- enable scl low
					sct 	<= '0';
				end if;
				
				if (counter = (Sclperiod + sclmid)) then -- counter in mid of scl low 
					
					if state = addressW then
					
						case count is
							when 8 =>
								dat <= slaveaddressW(7);
							when 7 =>
								dat <= slaveaddressW(6);
							when 6 =>
								dat <= slaveaddressW(5);
							when 5 =>
								dat <= slaveaddressW(4);
							when 4 =>
								dat <= slaveaddressW(3);
							when 3 =>
								dat <= slaveaddressW(2);
							when 2 =>
								dat <= slaveaddressW(1);
							when 1 =>
								dat <= slaveaddressW(0);	
								state <= midacknowledge;
							when others =>
								count := 8;
						end case;

						count := count -1 ;
					end if;
					
					if state = addressR then
					
						case count is
							when 8 =>
								dat <= slaveaddressR(7);
							when 7 =>
								dat <= slaveaddressR(6);
							when 6 =>
								dat <= slaveaddressR(5);
							when 5 =>
								dat <= slaveaddressR(4);
							when 4 =>
								dat <= slaveaddressR(3);
							when 3 =>
								dat <= slaveaddressR(2);
							when 2 =>
								dat <= slaveaddressR(1);
							when 1 =>
								dat <= slaveaddressR(0);	
								state <= midacknowledge;
							when others =>
								count := 8;
						end case;

						count := count -1 ;
					end if;
					
					if state = midacknowledge then
					
						
						if ReaWri = '1' then
								state <= regR;
								tristateenable:='0'; 
							else	
								state <= regW;
							end if;
						count:=8;
					end if;
					
					if state = regW then
					
						case count is
							when 8 =>
								dat <= Regaddress(7);
							when 7 =>
								dat <= Regaddress(6);
							when 6 =>
								dat <= Regaddress(5);
							when 5 =>
								dat <= Regaddress(4);
							when 4 =>
								dat <= Regaddress(3);
							when 3 =>
								dat <= Regaddress(2);
							when 2 =>
								dat <= Regaddress(1);
							when 1 =>
								dat <= Regaddress(0);	
								state <= acknowledge;
								ReaWri <= '1';
							when others =>
								count := 8;
						end case;

						count := count -1 ;
					end if;
					
					if state = regR then
					
						case count is
							when 8 =>
								data(7) <= sda;
							when 7 =>
								data(6) <= sda;
							when 6 =>
								data(5) <= sda;
							when 5 =>
								data(4) <= sda;
							when 4 =>
								data(3) <= sda;
							when 3 =>
								data(2) <= sda;
							when 2 =>
								data(1) <= sda;
							when 1 =>
								data(0) <= sda;
								state <= acknowledge;
								ReaWri <= '0';		
										

								
							when others =>
								count := 8;
						end case;
						

						count := count -1 ;
					end if;
					
					if state = acknowledge then
						state <= stopadjust;	
					end if;
					
					if state = stopadjust then
						
						tristateenable:='1'; 
						tristateenablescl := '1';
						dat <= '0';
						state <= stop;	
							
					end if;					
					
				end if;
			else	
                counter := 0;
            end if;
		counter := counter + 1;	
        end if;
		
		if tristateenable = '1' then		-- Sda tristate logic
		sda <= dat;
		else 
		sda <= 'Z';
		end if;
		
		if tristateenablescl = '1' then 	-- Scl tristate logic
		scl <= sct;
		else 
		scl <= 'Z';
		end if;
		
		leds <= data(4 downto 0); 			-- Output leds place what ever is read from slave register
    end process;
	

end Behavioral;

