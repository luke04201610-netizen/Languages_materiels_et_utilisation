library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity quadram_tb is
  generic (
    Nbits_sel  : positive := 2;
    Nbits_addr : positive := 8;
    Nbits_data : positive := 8
  );
end entity quadram_tb;

architecture bench of quadram_tb is

  constant NRAMS : positive := 2**Nbits_sel;   

  signal clock     : std_logic := '0';
  signal we        : std_logic := '0';
  signal address   : unsigned(Nbits_sel+Nbits_addr-1 downto 0) := (others => '0');
  signal datain    : unsigned(Nbits_data-1 downto 0) := (others => '0');
  signal dataout   : unsigned(Nbits_data-1 downto 0);
  signal StopClock : boolean := false;

begin

  UUT: entity work.quadram(RTL)
    generic map (Nbits_sel => Nbits_sel, Nbits_addr => Nbits_addr, Nbits_data => Nbits_data)
    port map (clock => clock, we => we, address => address,
              datain => datain, dataout => dataout);

  ClockGen: process is
  begin
    while not StopClock loop
      clock <= '0';
      wait for 5 ns;
      clock <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process ClockGen;

  Stim: process is
  begin
    wait until falling_edge(clock);


    we <= '1';
    for ram in 0 to NRAMS-1 loop
      address <= to_unsigned(ram * 2**Nbits_addr + 5, address'length);
      datain  <= to_unsigned(16#11# * (ram + 1), Nbits_data);
      wait until falling_edge(clock);
    end loop;
    we <= '0';

    for ram in 0 to NRAMS-1 loop
      address <= to_unsigned(ram * 2**Nbits_addr + 5, address'length);
      wait until falling_edge(clock);
      assert dataout = to_unsigned(16#11# * (ram + 1), Nbits_data)
        report "RAM " & integer'image(ram) & " : mauvaise valeur" severity error;
    end loop;

    report "Fin du test de quadram, " & integer'image(NRAMS) & " RAMs";
    StopClock <= true;
    wait;
  end process Stim;

end architecture bench;