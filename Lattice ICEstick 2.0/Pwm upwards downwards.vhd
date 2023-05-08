-- Usman Ali Butt
-- Dated : 5/6/2023
-- Lattice ICEStick
-- Time domain 0-200000 is 0.005 ms
-- Duty cycle reaching from 0 to 100% in 60 steps 200000/5000
-- and back to 0 in 60 steps
-- count 		is PWM frequency
-- dutycycle 	is PWM dutycycle
-- steps		is PWM steps
-- updown		is PWM direction upwards/downwards
library ieee;
use ieee.std_logic_1164.all;
 
entity led is

    port(clk : in std_logic;		    -- Clock
	A : out std_logic_vector(0 to 4)	-- Led outputs
	);    

end led;

architecture ledtest of led is

signal count, dutycycle	: integer range 0 to 300000 := 0;

begin

    process(clk) is
	variable updown: std_logic := '0';
	variable steps	: integer range 0 to 60 := 0;
    begin
        if rising_edge(clk) then
		
		count <= count + 1;
		
			if count = 300000 then      
			   count <= 0;
			   steps := steps + 1;
--Check if PWM direction changed and move dutycycle
--upwards 0-100% or downwards 100-0%
--In each step dutycycle is increased or decreased
--depending on direction of PWM 			   
			    if updown = '1' then
					dutycycle <= dutycycle - 5000 ;
				else
					dutycycle <= dutycycle + 5000 ;
				end if;
--Update updown after updown checked in above condition
--updown is a variable so instantaneously changed
--After 60 steps PWM cahnges direction and updown variable
--is used for here for direction change. updown cannot be 
--a signal. Inverted logic dosent work on signal. 				
			    if steps = 60 then
					updown := updown xor '1';
					steps := 0;
			    end if;
			   
			end if;
			 
--Switch leds 			
			if count <= dutycycle then
				A <= "11111";
			else
				A <= "10000";
			end if; 
	
        end if;
   end process;


end ledtest;
