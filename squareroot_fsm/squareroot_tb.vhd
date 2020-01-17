-- Author: Paolo Camurati
-- File : squareroot_hlsm.vhd
-- Design units:
-- entity squareroot
-- function: square root HSLM - asynchronous reset 
-- input: Clk, Rst, go, start(1 bit), a, b (8 bits)
-- output: ready (1 bit), res (9 bits)
-- architecture HSLM
-- Library/package:ieee.std_logic_ll64: to use std_logic
-- Synthesis and verification (optional):
-- Synthesis software: . . .
--  Options/script: . . .
--  Target technology: . . .
--  Testbench: squareroot_hlsm_tb.vhd
--  Revision history
--  Version 1.0
--  Date: 20170713
--  Comments:

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Testbench IS
END Testbench;

ARCHITECTURE TBarch OF Testbench IS
  COMPONENT squareroot IS
   PORT (Clk, Rst, start: IN std_logic;
			a, b: IN std_logic_vector(7 DOWNTO 0);
			res: OUT std_logic_vector(8 DOWNTO 0);
			ready: OUT std_logic );
  END COMPONENT;

  SIGNAL Clk_s, Rst_s, start_s, ready_s: std_logic;
  SIGNAL a_s, b_s: std_logic_vector(7 DOWNTO 0);
  SIGNAL res_s: std_logic_vector(8 DOWNTO 0);
  
  BEGIN
     CompToTest: squareroot PORT MAP (Clk_s, Rst_s, start_s, a_s, b_s, res_s, ready_s);

  ClkProcess: PROCESS
  BEGIN
    Clk_s <= '0';
    WAIT FOR 10 NS;
    Clk_s <= '1'; 
    WAIT FOR 10 NS;
  END PROCESS ClkProcess;

  VectorProcess: PROCESS
  BEGIN
    --a_s <= (others => '0');
	 --b_s <= (others => '0');
	 Rst_s <= '1';
    start_s <= '0';
    WAIT UNTIL Clk_s='1' AND Clk_s'EVENT;
    WAIT FOR 5 NS;
    Rst_s <= '0';
    start_s <= '1';
	 a_s <= "00000100";
    b_s <= "00000011";
    WAIT UNTIL Clk_s='1' AND Clk_s'EVENT;
    WAIT FOR 5 NS;
    start_s <= '0';
    WAIT; 
  END PROCESS VectorProcess;      
END TBarch;


