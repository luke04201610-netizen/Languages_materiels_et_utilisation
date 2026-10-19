-- Test bench of the address decoder 2 -> 4 (Q1)

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;

entity Decoder_TB is
end entity Decoder_TB;

architecture Bench of Decoder_TB is

  signal Sel : unsigned(1 downto 0);
  signal CS  : std_logic_vector(3 downto 0);

  type cs_table is array (0 to 3) of std_logic_vector(3 downto 0);
  constant EXPECTED : cs_table := ("0001", "0010", "0100", "1000");

begin

  UUT: entity work.decoder(RTL)
  port map (
    sel => Sel,
    cs  => CS
  );

  Stim: process is
    variable errors : natural := 0;
  begin

    -- every value of sel, 10 ns each
    for i in 0 to 3 loop
      sel <= to_unsigned(i, 2);
      wait for 10 ns;
      if cs /= EXPECTED(i) then
        errors := errors + 1;
        report "sel = " & integer'image(i) & ": wrong cs" severity error;
      end if;
    end loop;

    -- sel not valid: no RAM may be selected
    sel <= "XX";
    wait for 10 ns;
    if cs /= "0000" then
      errors := errors + 1;
      report "sel = XX: a RAM is selected" severity error;
    end if;

    if errors = 0 then
      report "Decoder OK";
    else
      report "Decoder FAILED: " & integer'image(errors) & " errors" severity error;
    end if;
    wait;
  end process;

end architecture Bench;
