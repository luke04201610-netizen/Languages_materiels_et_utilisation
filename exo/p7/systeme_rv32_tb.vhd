-- Testbench of systeme_rv32: 10 ns clock, reset until 25 ns, then the program
-- runs until ebreak. The program file is chosen with vsim -gPROG_FILE=...

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity systeme_rv32_tb is
  generic (PROG_FILE : string := "programme.txt");
end entity systeme_rv32_tb;

architecture Bench of systeme_rv32_tb is
  signal clock   : std_logic := '0';
  signal reset   : std_logic := '1';
  signal result  : std_logic_vector(31 downto 0);
  signal halted  : std_logic;
  signal illegal : std_logic;
begin

  UUT: entity work.systeme_rv32
    generic map (PROG_FILE => PROG_FILE)
    port map (clock => clock, reset => reset, show_reg => "01010",  -- a0 (x10)
              result => result, halted => halted, illegal => illegal);

  ClockGen: process is
  begin
    while halted /= '1' and now < 100 us loop
      clock <= '0'; wait for 5 ns;
      clock <= '1'; wait for 5 ns;
    end loop;
    report "Fin : halted = " & std_logic'image(halted) & ", illegal = " & std_logic'image(illegal);
    wait;
  end process ClockGen;

  reset <= '1', '0' after 25 ns;

end architecture Bench;
