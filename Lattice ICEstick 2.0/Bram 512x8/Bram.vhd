-- Dated : 24 July 2023
-- Author: Usman Ali Butt

-- External clk clock input 12Mhz
-- External leds D1,D2,D3,D4,D5 on icestick

-- Component SB_RAM512x8 instanciated 
-- Ram depth 512 bytes
-- Ram width 1 byte - 8 bits
-- Ram positive edge read and write
-- Ram speed 12Mhz

-- Array 'data' values are written in ram. At first
-- address first data value is written next address second
-- value, goes uptill 511. Total values are 5, at each
-- address of ram only one out of these 5 values can be present
-- at a time. These values at a single address move back and forth
-- depending on the 'count' variable.    

-- Ram is write first then read. In our case 
-- writing to all 511 addresses and then reading 
-- address 128.
-- On each write the data at address 128 changes depending 
-- on count variable
-- On next read you will see different pattern appear
-- on leds. 

-- Errors encountered
-- Ram primitves explained in the official documentation
-- are too important. I named the architecture as primitve 
-- name and synthesizer automatically fixed unknown
-- behaviour.
-- In floor plane of FPGA after synthesizer look at the 
-- signals. I clocked the RAM on positive read, write 
-- but synthesizer was auto changing the write to
-- negative edged. Fixed by placing the 'leds' output 
-- at positive edge "weird" 
  
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Bram is 
	 port(clk		 : in std_logic;
		  leds		 : out std_logic_vector(4 downto 0)
	 );
 end Bram;
 
 architecture ram4k of Bram is
 
	component SB_RAM512x8 
	generic (
	addr_width 	: natural := 9;--512x8
	data_width 	: natural := 8);
	port(
	write_en 	: in std_logic;
	waddr 		: in std_logic_vector 	(addr_width - 1 downto 0);
	wclk 		: in std_logic;
	wclk_e 		: in std_logic;
	read_en 	: in std_logic;
	raddr 		: in std_logic_vector 	(addr_width - 1 downto 0);
	rclk 		: in std_logic;
	rclk_e 		: in std_logic;
	din 		: in std_logic_vector 	(data_width - 1 downto 0);
	dout 		: out std_logic_vector 	(data_width - 1 downto 0));
	end component;
	
	constant addreswidth: natural := 9; 
	constant datawidth 	: natural := 8;
	signal Waddres 		: std_logic_vector 	(addreswidth 	-1 downto 0); 
	signal Wdata   		: std_logic_vector 	(datawidth 		-1 downto 0);
	signal Wclk_e	   	: std_logic;
	signal Rena    		: std_logic;
	signal Raddress 	: std_logic_vector 	(addreswidth 	-1 downto 0) ;
	signal Rdata   		: std_logic_vector	(datawidth 		-1 downto 0) ;
	signal Rclk_e	   	: std_logic;
	signal Wena    		: std_logic;
	
	-- Full ram will be populated with only these 5 values
	-- At any single address only one of the below values
    -- is writen.	
	type ramdata is array (0 to 4) of std_logic_vector(7 downto 0);
	signal data :ramdata := (
		 0 => "01011011",
		 1 => "10010101",
		 2 => "00101010",
		 3 => "11001100",
		 4 => "01101011"		 
	 );
	
	signal Winc  :integer range 0 to 512 := 0;
	signal Rinc  :integer range 0 to 512 := 0;
	signal count :integer range 0 to 5 :=0 ;
	signal Redata   		: std_logic_vector	(datawidth 		-1 downto 0) ;
 begin
 u1: SB_RAM512x8 generic map(addreswidth,datawidth) port map(Wena,Waddres,clk,Wclk_e,Rena,Raddress,clk,Rclk_e,Wdata,Rdata);

 
	process (clk)
	variable timeer: integer range 0 to 100000 := 0;
	begin
		if (clk'event and clk='1') then	
			-- Write until all 512 address are writen		
			if Winc <= 511 then
				Wena 	<= '1';
				Wclk_e	<= '1';
				Rena	<= '0';
				Rclk_e	<= '0';
				Waddres <= std_logic_vector(to_unsigned(Winc, Waddres'length));
				Wdata   <= data(count);
				count   <= count	+	1;
				-- Data array start over if reached 5
					if count = 4 then
						count <= 0 ;
					end if;	
				Winc   	<= Winc 	+ 	1;
			elsif Winc > 511  then
				Wena 	<= '0';
				Wclk_e	<= '0';
				Rena	<= '1';
				Rclk_e	<= '1'; 
				-- Read from address 128
				Raddress <= std_logic_vector(to_unsigned(128, Raddress'length));
				
				timeer := timeer + 1;
				-- Arbitrary delay for leds data change to be noticiable.
					if timeer = 100000 then
						Rinc   	<= Rinc 	+ 	1; 
						timeer	:= 0;
					end if;
				 
					if Rinc = 511 then
						Rinc <= 0 ;
						Winc <= 0 ;
					end if;		
						
				Redata <= Rdata;				
				leds <= Redata(4 downto 0);
				
					
			end if;	
		end if;	
		
	end process;
	 	
	 
 end ram4k;