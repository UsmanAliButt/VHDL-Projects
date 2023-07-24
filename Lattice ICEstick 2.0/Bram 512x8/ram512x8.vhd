-- Dated : 24 July 2023
-- Author: Usman Ali Butt
--
-- Ram component for lattice ICEstick40
-- Please take a look at official lattice 
-- Memory-Usage-Guide-for-iCE40-Devices.pdf
-- Bram FPGA block can be used as FIFO, RAM etc.
-- RAM primitives are well explained in the official
-- document. 
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity SB_RAM512x8 is
generic (
	addr_width : natural := 9;--512x8
	data_width : natural := 8);
port (
	write_en : in std_logic;
	waddr 	: in std_logic_vector (addr_width - 1 downto 0);
	wclk 	: in std_logic;
	wclk_e 	: in std_logic;
	read_en : in std_logic;
	raddr 	: in std_logic_vector (addr_width - 1 downto 0);
	rclk 	: in std_logic;
	rclk_e 	: in std_logic;
	din 	: in std_logic_vector (data_width - 1 downto 0);
	dout 	: out std_logic_vector (data_width - 1 downto 0));
end SB_RAM512x8;

architecture rtl of SB_RAM512x8 is
	type mem_type is array ((2** addr_width) - 1 downto 0) of
	std_logic_vector(data_width - 1 downto 0);
	signal mem : mem_type;

begin

	process (wclk)
	-- Write memory.
	begin
		if(wclk_e = '1') then
			if (wclk'event and wclk = '1') then
				if (write_en = '1') then
					mem(conv_integer(waddr)) <= din;
				end if;
			end if;
		end if;	
	end process;
		
	process (rclk) 
	-- Read memory.
	begin
		if(rclk_e = '1') then
			if (rclk'event and rclk = '1') then
				if (read_en = '1') then
					dout <= mem(conv_integer(raddr));
				end if;
			end if;
		end if;	
	end process;

end rtl;