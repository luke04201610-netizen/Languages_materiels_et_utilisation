-- test bench solution to ex09

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;

entity Ram_TB is
end entity Ram_TB;

architecture Bench of Ram_TB is

  signal Address :Std_logic_vector(9 downto 0);
  signal DataIn, DataOut :Std_logic_vector(7 downto 0);
  signal WE : Std_logic;
  signal clock : Std_logic;
  signal StopClock : boolean := FALSE;

begin

  UUT: entity work.sync_ram(RTL)
  port map (
    clock   => clock,
    we      => WE,
    address => Address,
    datain  => DataIn,
    DataOut => DataOut
  );

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

    wait until rising_edge(clock); -- cycle 1
    datain <=    "00000000";
    address <= "0000000001";
    we <= '0';

    wait until rising_edge(clock); -- cycle 2
    we <= '1';
    datain <= "00000100";

    wait until rising_edge(clock); -- cycle 3
    datain <=    "00000111";
    address <= "0000000010";

    wait until rising_edge(clock); -- cycle 4
    we <= '0';

    wait until rising_edge(clock); -- cycle 5
    address <= "0000000001";

    wait until rising_edge(clock); -- cycle 6
    address <= "0000000010";

    wait until rising_edge(clock); -- cycle 7
    wait until rising_edge(clock); -- cycle 8

    StopClock <= true;
    wait;
  end process;

end architecture Bench;

architecture Bench2 of Ram_TB is

  signal Address :Std_logic_vector(9 downto 0);
  signal DataIn, DataOut :Std_logic_vector(7 downto 0);
  signal WE : Std_logic;
  signal clock : Std_logic;
  signal StopClock : boolean := FALSE;

  signal ok: boolean := true;

begin

  UUT: entity work.sync_ram(RTL)
  port map (
    clock   => clock,
    we      => WE,
    address => Address,
    datain  => DataIn,
    DataOut => DataOut
  );

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

    -- Initialise input signals
    address <= "0000000000";
    datain  <=   "00000000";
    we <= '0';
    wait until rising_edge(clock);

    -- write to all addresses
    while address /= "1111111111" loop
      we <= '1';
      wait until rising_edge(clock);
      address <= std_logic_vector(unsigned(address) + 1);
      datain  <= std_logic_vector(unsigned(datain) + 1);
    end loop;

    -- stop writing
    address <= "0000000000";
    datain  <=   "00000000";
    we <= '0';
    wait until rising_edge(clock);

    -- read from all addresses
    while address /= "1111111111" loop
      address <= std_logic_vector(unsigned(address) + 1);
      wait until rising_edge(clock);
      -- ok should permanently go false on the first error
      ok <= ok and dataout = std_logic_vector(unsigned(address(7 downto 0)) - 1);
    end loop;

    StopClock <= true;
    wait;
  end process;

end architecture Bench2;
