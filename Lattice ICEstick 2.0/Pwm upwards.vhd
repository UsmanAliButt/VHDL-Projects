-- Usman Ali Butt
-- Dated : 5/5/2023
-- Lattice ICEStick
-- Time domain 0-200000 is 0.005 ms
-- Duty cycle reaching from 0 to 100% in
-- 40 steps 200000/5000
library ieee;
use ieee.std_logic_1164.all;
 
entity led is

    port(clk : in std_logic;		-- Clock
	A : out std_logic_vector(0 to 4)	-- Led outputs
	);    

end led;

architecture ledtest of led is

signal count: integer range 0 to 200000 := 0;
signal dutycycle: integer :=0;

begin

    process(clk) is
    begin
        if rising_edge(clk) then
		count <= count + 1; 
	
			if count = 200000 then      -- 40 steps in PWM 200000/5000
			   count <= 0;
			   dutycycle <= dutycycle + 5000 ;
				if dutycycle = 200000 then
					dutycycle <= 0;
				end if;
			end if;

			if count <= dutycycle then
				A <= "11111";
			else
				A <= "10000";
			end if; 
	
        end if;
   end process;


end ledtest;
