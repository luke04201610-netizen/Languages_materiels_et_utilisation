library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity quadram_tb is
end entity quadram_tb;

architecture bench of quadram_tb is

  signal clock     : std_logic := '0';
  signal we        : std_logic := '0';
  signal address   : unsigned(9 downto 0) := (others => '0');
  signal datain    : unsigned(7 downto 0) := (others => '0');
  signal dataout   : unsigned(7 downto 0);
  signal StopClock : boolean := false;

begin

  UUT: entity work.quadram(RTL)
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
    address <= to_unsigned(16#005#, 10);  datain <= to_unsigned(16#11#, 8);
    wait until falling_edge(clock);
    address <= to_unsigned(16#105#, 10);  datain <= to_unsigned(16#22#, 8);
    wait until falling_edge(clock);
    address <= to_unsigned(16#205#, 10);  datain <= to_unsigned(16#33#, 8);
    wait until falling_edge(clock);
    address <= to_unsigned(16#305#, 10);  datain <= to_unsigned(16#44#, 8);
    wait until falling_edge(clock);
    we <= '0';

  
    address <= to_unsigned(16#005#, 10);
    wait until falling_edge(clock);
    assert dataout = to_unsigned(16#11#, 8) report "RAM0 : mauvaise valeur" severity error;
    address <= to_unsigned(16#105#, 10);
    wait until falling_edge(clock);
    assert dataout = to_unsigned(16#22#, 8) report "RAM1 : mauvaise valeur" severity error;
    address <= to_unsigned(16#205#, 10);
    wait until falling_edge(clock);
    assert dataout = to_unsigned(16#33#, 8) report "RAM2 : mauvaise valeur" severity error;
    address <= to_unsigned(16#305#, 10);
    wait until falling_edge(clock);
    assert dataout = to_unsigned(16#44#, 8) report "RAM3 : mauvaise valeur" severity error;

    report "Fin du test de quadram";
    StopClock <= true;
    wait;
  end process Stim;

end architecture bench;