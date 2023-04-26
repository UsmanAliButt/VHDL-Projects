-- Usman Ali Butt
-- Dated : 26/4/2023
-- Lattice ICEStick
library ieee;
use ieee.std_logic_1164.all;
 
entity led is

    port(clk : in std_logic;		-- Clock
	A : out std_logic_vector(0 to 4)	-- Led outputs
	);    

end led;

architecture ledtest of led is

signal count: integer range 0 to 20000000 := 0;
signal B : std_logic_vector(0 to 4) := "00000";

begin

    process(clk) is
    begin
        if rising_edge(clk) then
	count <= count + 1; 
	if count = 20000000 then
	   count <= 0;	
	end if;
        
	case(count) is
	 when 5000000 =>  
		B <= "11000";
	 when 10000000 =>
		B <= "10100";
	 when 15000000 =>
		B <= "10010";
	 when 20000000 =>
		B <= "10001";
	 when others =>
		A <= B;
	end case;
     end if;
   end process;

end ledtest;
