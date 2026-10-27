-- test bench solution to ex09

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;

entity Ram_TB is  
generic (
    Nbits_addr : positive := 10;
    Nbits_data : positive := 8
  );
end entity Ram_TB;

architecture Bench of Ram_TB is

  signal Address :unsigned(Nbits_addr-1 downto 0);
  signal DataIn, DataOut :unsigned(Nbits_data-1 downto 0);
  signal WE : Std_logic;
  signal clock : Std_logic;
  signal StopClock : boolean := FALSE;
  signal cs : std_logic := '0';

begin

  UUT: entity work.sync_ram(RTL)
  generic map (
  Nbits_addr => Nbits_addr,
  Nbits_data => Nbits_data
)
  port map (
    clock   => clock,
    we      => WE,
    address => Address,
    datain  => DataIn,
    dataout => DataOut,
    cs      => cs
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
    cs <= '1';                     -- 先选中 RAM，原来的场景照常跑

    wait until rising_edge(clock); -- cycle 1
    datain  <= (others => '0');
    address <= to_unsigned(1, Nbits_addr);
    we <= '0';

    wait until rising_edge(clock); -- cycle 2
    we <= '1';
    datain <= to_unsigned(4, Nbits_data);

    wait until rising_edge(clock); -- cycle 3
    datain  <= to_unsigned(7, Nbits_data);
    address <= to_unsigned(2, Nbits_addr);

    wait until rising_edge(clock); -- cycle 4
    we <= '0';

    wait until rising_edge(clock); -- cycle 5
    address <= to_unsigned(1, Nbits_addr);

    wait until rising_edge(clock); -- cycle 6
    address <= to_unsigned(2, Nbits_addr);

    wait until rising_edge(clock); -- cycle 7
    -- CS 测试 1：在两个时钟沿之间取消选中，dataout 应立刻变成 Z
    wait for 2 ns;
    cs <= '0';

    wait until rising_edge(clock); -- cycle 8
    -- CS 测试 2：cs = 0 时尝试往地址 1 写 9，应该写不进去
    address <= to_unsigned(1, Nbits_addr);
    datain  <= to_unsigned(9, Nbits_data);
    we <= '1';

    wait until rising_edge(clock); -- cycle 9
    we <= '0';
    -- CS 测试 3：在两个时钟沿之间重新选中，dataout 应立刻显示旧值 4
    wait for 2 ns;
    cs <= '1';

    wait until rising_edge(clock); -- cycle 10
    wait until rising_edge(clock); -- cycle 11
    StopClock <= true;
    wait;
  end process;

end architecture Bench;

architecture Bench2 of Ram_TB is
  signal Address :unsigned(Nbits_addr-1 downto 0);
  signal DataIn, DataOut :unsigned(Nbits_data-1 downto 0);
  signal WE : Std_logic;
  signal clock : Std_logic;
  signal StopClock : boolean := FALSE;
  signal cs : std_logic := '1';

  signal ok: boolean := true;

begin

  UUT: entity work.sync_ram(RTL)
  generic map (
  Nbits_addr => Nbits_addr,
  Nbits_data => Nbits_data
)
  port map (
    clock   => clock,
    we      => WE,
    address => Address,
    datain  => DataIn,
    DataOut => DataOut,
    cs      => cs
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
    address <= (others => '0');
    datain  <=   (others => '0');
    we <= '0';
    cs <= '1';
    wait until rising_edge(clock);

    -- write to all addresses
    while address /= (address'range => '1') loop
      we <= '1';
      wait until rising_edge(clock);
      address <= unsigned(address) + 1;
      datain  <= unsigned(datain) + 1;
    end loop;

    -- stop writing
    address <= (others => '0');
    datain  <=   (others => '0');
    we <= '0';
    wait until rising_edge(clock);

    -- read from all addresses
    while address /= (address'range => '1') loop
      address <= unsigned(address) + 1;
      wait until rising_edge(clock);
      -- ok should permanently go false on the first error
      ok <= ok and dataout = unsigned(address(7 downto 0)) - 1;
    end loop;

    StopClock <= true;
    wait;
  end process;

end architecture Bench2;
