LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL; 


ENTITY squareroot IS
   PORT (Clk, Rst, start: IN std_logic;
			a, b: IN std_logic_vector(7 DOWNTO 0);
			res: OUT std_logic_vector(8 DOWNTO 0);
			ready: OUT std_logic );
END squareroot;

ARCHITECTURE FSMD OF squareroot IS

 -- Controller state signals
  TYPE Statetype IS (idle, s1, s2, s3, s4, s5);
  SIGNAL Currstate, Nextstate: Statetype;
 
-- Shared signals
  SIGNAL r12ld, r3ld, r1GTr2, r3LTr2: std_logic;
  SIGNAL mpx12sel, mpx3sel: std_logic_vector(1 DOWNTO 0);
  
-- Datapath signals
  SIGNAL r1, r2, r3, r1Next, r2Next, r3Next: signed(8 DOWNTO 0);

BEGIN

   ------ Datapath processes ------

  DPCombLogic: PROCESS (r12ld, r3ld, mpx12sel, mpx3sel,r1,r2,r3,a,b)
  BEGIN
    IF (r1 > r2) THEN
	   r1GTr2 <= '1';
	 ELSE
	   r1GTr2 <= '0';
	 END IF;

    IF (r3 < r2) THEN
	   r3LTr2 <= '1';
	 ELSE
	   r3LTr2 <= '0';
	 END IF;
	 
    CASE mpx12sel IS
	 
      WHEN "00" => 
        r1Next <= signed(a(7) & a);
        r2Next <= signed(b(7) & b);
        
      WHEN "01" =>
        r1Next <= ABS(r1);
        r2Next <= ABS(r2);

      WHEN "10" =>
        r1Next <= r2;
        r2Next <= r1;

      WHEN OTHERS =>
        r1Next <= r1;
        r2Next <= r2;

    END CASE;

    CASE mpx3sel IS
	 
      WHEN "00" => 
        r3Next <= r2 - ("000" & r2(8 DOWNTO 3));
        
      WHEN "01" =>
        r3Next <= r3 + ('0' & r1(8 DOWNTO 1));
      
		WHEN "10" => 
        r3Next <= r2;
      
		WHEN OTHERS =>
        r3Next <= r3;
           
    END CASE;

    res <= std_logic_vector(r3);

  END PROCESS DPCombLogic; 

  DPRegs: PROCESS (Clk, Rst)
  BEGIN
    IF (Rst = '1') THEN
      r1 <= (OTHERS => '0');
      r2 <= (OTHERS => '0');
		r3 <= (OTHERS => '0');
    ELSIF (Clk = '1' AND Clk'EVENT) THEN
	   IF (r12ld = '1') THEN
        r1 <= r1Next;
        r2 <= r2Next;
		END IF;
		IF (r3ld = '1') THEN
        r3 <= r3Next;
		END IF;
    END IF;

  END PROCESS DPRegs;    

    ------ Controller processes ------   

  CntlCombLogic: PROCESS (start, Currstate, r1GTr2, r3LTr2)
  BEGIN
    ready <= '0';
    mpx12sel <= "11";
    mpx3sel <= "11";
    r12ld <= '0';
    r3ld <= '0';
  
    CASE Currstate IS
      WHEN idle => 
        ready <= '1';
		  r12ld <= '1';
        IF (start = '1') THEN
          mpx12sel <= "00";
			 Nextstate <= s1;
        ELSE
          Nextstate <= idle;
        END IF;
		  
      WHEN s1 =>
		  r12ld <= '1';
        mpx12sel <= "01";
		  Nextstate <= s2;
		  
      WHEN s2 =>
        IF (r1GTr2 = '1') THEN
          mpx12sel <= "10";
		  ELSE
          mpx12sel <= "11";
        END IF;
 		  r12ld <= '1';
	     Nextstate <= s3;

      WHEN s3 =>
        mpx3sel <= "00";
		  r3ld <= '1';
	     Nextstate <= s4;
		  
      WHEN s4 =>
        mpx3sel <= "01";
		  r3ld <= '1';
	     Nextstate <= s5;

      WHEN s5 =>
        ready <= '0';
        IF (r3LTr2 = '1') THEN
          mpx3sel <= "10";
		  ELSE
          mpx3sel <= "11";
        END IF;
 		  r3ld <= '1';
	     Nextstate <= idle;
		  
    END CASE;
  END PROCESS CntlCombLogic; 

  CntlRegs: PROCESS (Clk, Rst)
  BEGIN
    IF (Rst = '1') THEN
      Currstate <= idle;
    ELSIF (Clk = '1' AND Clk'EVENT) THEN
      Currstate <= Nextstate;
    END IF;
  END PROCESS CntlRegs;    

END FSMD;
