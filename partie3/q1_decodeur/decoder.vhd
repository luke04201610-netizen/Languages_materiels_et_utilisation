-- Address decoder 2 -> 4 (Q1)
--   sel: number of the RAM, taken from the address MSBs
--   cs : chip selects, one-hot, active high: cs(i) = '1' when sel = i

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity decoder is
  port (
    sel : in  unsigned(1 downto 0);
    cs  : out std_logic_vector(3 downto 0)
  );
end entity decoder;

architecture RTL of decoder is
begin

  with sel select
    cs <= "0001" when "00",
          "0010" when "01",
          "0100" when "10",
          "1000" when "11",
          "0000" when others;  -- sel not valid ('U', 'X'...): no RAM selected

end architecture RTL;
