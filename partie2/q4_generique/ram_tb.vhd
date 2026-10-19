-- test bench solution to ex09
--
-- Q2: signals of type unsigned
-- Q4: the test bench is generic too, the size of the RAM under test is chosen when
--     the simulation is loaded, e.g.:  vsim -gNbits_addr=4 -gNbits_data=16 work.ram_tb(bench2)

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;

entity Ram_TB is
  generic (
    Nbits_addr : positive := 10;
    Nbits_data : positive := 8
  );
end entity Ram_TB;

-- Short scenario of the original test bench (needs Nbits_addr >= 2, Nbits_data >= 3)
architecture Bench of Ram_TB is

  signal Address : unsigned(Nbits_addr-1 downto 0);
  signal DataIn, DataOut : unsigned(Nbits_data-1 downto 0);
  signal WE : Std_logic;
  signal clock : Std_logic;
  signal StopClock : boolean := FALSE;

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
    datain  <= to_unsigned(0, Nbits_data);
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
    wait until rising_edge(clock); -- cycle 8

    StopClock <= true;
    wait;
  end process;

end architecture Bench;

-- Writes then reads back every address, and checks the data read
architecture Bench2 of Ram_TB is

  signal Address : unsigned(Nbits_addr-1 downto 0);
  signal DataIn, DataOut : unsigned(Nbits_data-1 downto 0);
  signal WE : Std_logic;
  signal clock : Std_logic;
  signal StopClock : boolean := FALSE;

  signal ok: boolean := true;

  constant NWORDS : positive := 2**Nbits_addr;

  -- Word written at address i. The original test bench wrote the address itself,
  -- truncated to 8 bits: the 2 MSBs of the address were lost, so a RAM ignoring
  -- them would still pass. Here the address is folded on the data width with xor,
  -- so that every address bit changes the data.
  function pattern(i : natural) return unsigned is
    constant a : unsigned(Nbits_addr-1 downto 0) := to_unsigned(i, Nbits_addr);
    variable d : unsigned(Nbits_data-1 downto 0) := (others => '0');
  begin
    for b in a'range loop
      d(b mod Nbits_data) := d(b mod Nbits_data) xor a(b);
    end loop;
    return d;
  end function pattern;

  -- unsigned -> string such as "0101ZZUU", for the messages
  function to_str(v : unsigned) return string is
    constant CHARS : string(1 to 9) := "UX01ZWLH-";
    variable s : string(1 to v'length);
    variable k : positive := 1;
  begin
    for b in v'range loop
      s(k) := CHARS(std_ulogic'pos(v(b)) + 1);
      k := k + 1;
    end loop;
    return s;
  end function to_str;

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

  -- The inputs change on the falling edge of the clock, half a period before the
  -- rising edge where the RAM samples them.
  Stim: process is

    variable errors : natural := 0;

    -- counts and reports an error when the condition is false
    procedure check(condition : boolean; msg : string) is
    begin
      if not condition then
        errors := errors + 1;
        ok <= false;
        report msg severity error;
      end if;
    end procedure check;

  begin

    -- Initialise input signals
    address <= (others => '0');
    datain  <= (others => '0');
    we <= '0';
    wait until falling_edge(clock);

    -- write to all addresses
    we <= '1';
    for i in 0 to NWORDS-1 loop
      address <= to_unsigned(i, Nbits_addr);
      datain  <= pattern(i);
      wait until falling_edge(clock);  -- written on the rising edge in between
    end loop;

    -- stop writing
    we <= '0';

    -- read from all addresses: the word comes out after the rising edge that
    -- samples the address (synchronous read), it is checked on the next falling edge
    for i in 0 to NWORDS-1 loop
      address <= to_unsigned(i, Nbits_addr);
      wait until falling_edge(clock);
      check(dataout = pattern(i), "address " & integer'image(i) & ": read "
            & to_str(dataout) & ", expected " & to_str(pattern(i)));
    end loop;

    if errors = 0 then
      report "Bench2 OK: " & integer'image(NWORDS) & " words of "
           & integer'image(Nbits_data) & " bits written and read back";
    else
      report "Bench2 FAILED: " & integer'image(errors) & " errors" severity error;
    end if;

    StopClock <= true;
    wait;
  end process;

end architecture Bench2;
