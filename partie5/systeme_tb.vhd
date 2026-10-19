-- Test bench of the complete system (partie 5): clock and reset.
-- The simulation ends when the processor executes ebreak ($finish).

library IEEE;
use IEEE.Std_logic_1164.all;

entity Systeme_TB is
end entity Systeme_TB;

architecture Bench of Systeme_TB is

  signal clock : std_logic := '0';
  signal reset : std_logic := '1';

begin

  UUT: entity work.systeme(struct)
  port map (
    clock => clock,
    reset => reset
  );

  clock <= not clock after 5 ns;  -- period 10 ns
  reset <= '0' after 12 ns;       -- the processor is reset on the first falling edge (10 ns)

  -- stops the simulation if the program never reaches ebreak
  Watchdog: process is
  begin
    wait for 100 us;
    report "Timeout: the program did not reach ebreak" severity failure;
    wait;
  end process Watchdog;

end architecture Bench;
