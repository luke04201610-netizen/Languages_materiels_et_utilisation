-- Test bench of the quadram made of 4 sync_ram (Q3)

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;

entity Quadram_TB is
end entity Quadram_TB;

-- Writes the same offset in the 4 RAMs, then reads them back
architecture Bench of Quadram_TB is

  signal Address : unsigned(9 downto 0);
  signal DataIn, DataOut : unsigned(7 downto 0);
  signal WE : Std_logic;
  signal clock : Std_logic;
  signal StopClock : boolean := FALSE;

begin

  UUT: entity work.quadram(RTL)
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
  -- rising edge where the RAMs sample them.
  Stim: process is
  begin

    -- Initialise input signals
    address <= (others => '0');
    datain  <= (others => '0');
    we <= '0';
    wait until falling_edge(clock);

    -- write at the same offset (5) of the 4 RAMs: x"11" in RAM 0 ... x"44" in RAM 3
    we <= '1';
    for ram in 0 to 3 loop
      address <= to_unsigned(ram, 2) & to_unsigned(5, 8);
      datain  <= to_unsigned(16#11# * (ram + 1), 8);
      wait until falling_edge(clock);  -- written on the rising edge in between
    end loop;

    -- stop writing
    we <= '0';

    -- read them back: each RAM must give back its own word
    for ram in 0 to 3 loop
      address <= to_unsigned(ram, 2) & to_unsigned(5, 8);
      wait until falling_edge(clock);
      assert dataout = to_unsigned(16#11# * (ram + 1), 8)
        report "RAM " & integer'image(ram) & ": wrong word" severity error;
    end loop;

    StopClock <= true;
    wait;
  end process;

end architecture Bench;

-- Writes then reads back every address of the quadram, and checks the data read
architecture Bench2 of Quadram_TB is

  constant Nbits      : positive := 10;  -- address width of the quadram
  constant Nbits_data : positive := 8;
  constant NWORDS     : positive := 2**Nbits;

  signal Address : unsigned(Nbits-1 downto 0);
  signal DataIn, DataOut : unsigned(Nbits_data-1 downto 0);
  signal WE : Std_logic;
  signal clock : Std_logic;
  signal StopClock : boolean := FALSE;

  signal ok: boolean := true;

  -- Word written at address i: the address folded on the data width with xor, so
  -- that the RAM number (address MSBs) changes the data too. With data = address
  -- truncated to 8 bits, a quadram writing its 4 RAMs at once would pass the test.
  function pattern(i : natural) return unsigned is
    constant a : unsigned(Nbits-1 downto 0) := to_unsigned(i, Nbits);
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

  UUT: entity work.quadram(RTL)
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
  -- rising edge where the RAMs sample them.
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

    -- write to all addresses, i.e. to the 4 RAMs
    we <= '1';
    for i in 0 to NWORDS-1 loop
      address <= to_unsigned(i, Nbits);
      datain  <= pattern(i);
      wait until falling_edge(clock);  -- written on the rising edge in between
    end loop;

    -- stop writing
    we <= '0';

    -- read from all addresses: the word comes out after the rising edge that
    -- samples the address, it is checked on the next falling edge
    for i in 0 to NWORDS-1 loop
      address <= to_unsigned(i, Nbits);
      wait until falling_edge(clock);
      check(dataout = pattern(i), "address " & integer'image(i) & ": read "
            & to_str(dataout) & ", expected " & to_str(pattern(i)));
    end loop;

    if errors = 0 then
      report "Bench2 OK: " & integer'image(NWORDS)
           & " words (4 RAMs of 256 words) written and read back";
    else
      report "Bench2 FAILED: " & integer'image(errors) & " errors" severity error;
    end if;

    StopClock <= true;
    wait;
  end process;

end architecture Bench2;
