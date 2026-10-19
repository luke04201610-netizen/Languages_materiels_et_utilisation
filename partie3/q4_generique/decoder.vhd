-- Generic address decoder (Q4): Nbits_in -> 2**Nbits_in
--   sel: number of the RAM, taken from the address MSBs
--   cs : chip selects, one-hot, active high: cs(i) = '1' when sel = i

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity decoder is
  generic (
    Nbits_in : positive := 2
  );
  port (
    sel : in  unsigned(Nbits_in-1 downto 0);
    cs  : out std_logic_vector(2**Nbits_in-1 downto 0)
  );
end entity decoder;

architecture RTL of decoder is
begin

  -- one comparator per output (sel not valid: every comparison is false,
  -- no RAM selected)
  CSGEN: for i in cs'range generate
    cs(i) <= '1' when sel = i else '0';
  end generate CSGEN;

end architecture RTL;
