-- Test bench of the generic address decoder (Q4), e.g.:  vsim -gNbits_in=3 work.decoder_tb(bench)

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;

entity Decoder_TB is
  generic (
    Nbits_in : positive := 2
  );
end entity Decoder_TB;

architecture Bench of Decoder_TB is

  signal Sel : unsigned(Nbits_in-1 downto 0);
  signal CS  : std_logic_vector(2**Nbits_in-1 downto 0);

begin

  UUT: entity work.decoder(RTL)
  generic map (
    Nbits_in => Nbits_in
  )
  port map (
    sel => Sel,
    cs  => CS
  );

  Stim: process is
    variable expected : std_logic_vector(CS'range);
    variable errors : natural := 0;
  begin

    -- every value of sel, 10 ns each: only cs(sel) is '1'
    for i in 0 to 2**Nbits_in-1 loop
      sel <= to_unsigned(i, Nbits_in);
      wait for 10 ns;
      expected := (others => '0');
      expected(i) := '1';
      if cs /= expected then
        errors := errors + 1;
        report "sel = " & integer'image(i) & ": wrong cs" severity error;
      end if;
    end loop;

    -- sel not valid: no RAM may be selected
    sel <= (others => 'X');
    wait for 10 ns;
    expected := (others => '0');
    if cs /= expected then
      errors := errors + 1;
      report "sel not valid: a RAM is selected" severity error;
    end if;

    if errors = 0 then
      report "Decoder OK: " & integer'image(Nbits_in) & " -> "
           & integer'image(2**Nbits_in);
    else
      report "Decoder FAILED: " & integer'image(errors) & " errors" severity error;
    end if;
    wait;
  end process;

end architecture Bench;
