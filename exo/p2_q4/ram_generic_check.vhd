-- Additional architecture for Ram_TB: compile after ram_tb.vhd.
-- Checks every word with two complementary patterns, for any positive widths.
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture GenericCheck of Ram_TB is
  constant NWORDS : positive := 2**Nbits_addr;
  signal clock : std_logic := '0';
  signal we : std_logic := '0';
  signal address : unsigned(Nbits_addr-1 downto 0) := (others => '0');
  signal datain : unsigned(Nbits_data-1 downto 0) := (others => '0');
  signal dataout : unsigned(Nbits_data-1 downto 0);
  signal StopClock : boolean := false;
  signal ok : boolean := true;

  function pattern(i : natural; pass_id : natural) return unsigned is
    constant a : unsigned(Nbits_addr-1 downto 0) := to_unsigned(i, Nbits_addr);
    variable d : unsigned(Nbits_data-1 downto 0) := (others => '0');
  begin
    for b in a'range loop
      d(b mod Nbits_data) := d(b mod Nbits_data) xor a(b);
    end loop;
    if pass_id = 1 then
      return not d;
    end if;
    return d;
  end function;
begin
  UUT: entity work.sync_ram(RTL)
    generic map (Nbits_addr => Nbits_addr, Nbits_data => Nbits_data)
    port map (clock => clock, we => we, address => address,
              datain => datain, dataout => dataout);

  ClockGen: process
  begin
    while not StopClock loop
      clock <= '0';
      wait for 5 ns;
      clock <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process;

  Stim: process
    variable errors : natural := 0;
  begin
    wait until falling_edge(clock);
    for pass_id in 0 to 1 loop
      we <= '1';
      for i in 0 to NWORDS-1 loop
        address <= to_unsigned(i, Nbits_addr);
        datain <= pattern(i, pass_id);
        wait until falling_edge(clock);
      end loop;
      we <= '0';
      for i in 0 to NWORDS-1 loop
        address <= to_unsigned(i, Nbits_addr);
        wait until falling_edge(clock);
        if dataout /= pattern(i, pass_id) then
          errors := errors + 1;
          ok <= false;
          report "GenericCheck mismatch: pass " & integer'image(pass_id)
            & ", address " & integer'image(i) severity error;
        end if;
      end loop;
    end loop;
    if errors = 0 then
      report "GenericCheck OK: " & integer'image(NWORDS) & " words x "
        & integer'image(Nbits_data) & " bits, two complementary passes";
    else
      report "GenericCheck FAILED: " & integer'image(errors) & " errors"
        severity failure;
    end if;
    StopClock <= true;
    wait;
  end process;
end architecture GenericCheck;
