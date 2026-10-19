-- Test bench of the generic quadram (Q4), the configuration is chosen when the
-- simulation is loaded, e.g.:  vsim -gN=8 -gNbits_addr=4 -gNbits_data=16 work.quadram_tb(bench2)

library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_std.all;
use work.util_pkg.all;

entity Quadram_TB is
  generic (
    N          : positive := 4;
    Nbits_addr : positive := 8;
    Nbits_data : positive := 8
  );
end entity Quadram_TB;

-- Writes the same offset in every RAM, then reads them back
-- (needs Nbits_addr >= 3, and x"11" * N must fit in Nbits_data bits)
architecture Bench of Quadram_TB is

  constant Nbits : positive := log2ceil(N) + Nbits_addr;  -- address width of the quadram

  signal Address : unsigned(Nbits-1 downto 0);
  signal DataIn, DataOut : unsigned(Nbits_data-1 downto 0);
  signal WE : Std_logic;
  signal clock : Std_logic;
  signal StopClock : boolean := FALSE;

  -- address of the word "offset" of the RAM number "ram"
  function addr(ram, offset : natural) return unsigned is
  begin
    return to_unsigned(ram, Nbits - Nbits_addr) & to_unsigned(offset, Nbits_addr);
  end function addr;

begin

  UUT: entity work.quadram(RTL)
  generic map (
    N          => N,
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
  -- rising edge where the RAMs sample them.
  Stim: process is
  begin

    -- Initialise input signals
    address <= (others => '0');
    datain  <= (others => '0');
    we <= '0';
    wait until falling_edge(clock);

    -- write at the same offset (5) of every RAM: x"11" in RAM 0, x"22" in RAM 1...
    we <= '1';
    for ram in 0 to N-1 loop
      address <= addr(ram, 5);
      datain  <= to_unsigned(16#11# * (ram + 1), Nbits_data);
      wait until falling_edge(clock);  -- written on the rising edge in between
    end loop;

    -- stop writing
    we <= '0';

    -- read them back: each RAM must give back its own word
    for ram in 0 to N-1 loop
      address <= addr(ram, 5);
      wait until falling_edge(clock);
      assert dataout = to_unsigned(16#11# * (ram + 1), Nbits_data)
        report "RAM " & integer'image(ram) & ": wrong word" severity error;
    end loop;

    StopClock <= true;
    wait;
  end process;

end architecture Bench;

-- Writes then reads back every address of the quadram, and checks the data read
architecture Bench2 of Quadram_TB is

  constant Nbits  : positive := log2ceil(N) + Nbits_addr;  -- address width of the quadram
  constant NWORDS : positive := N * 2**Nbits_addr;         -- number of words of the quadram

  signal Address : unsigned(Nbits-1 downto 0);
  signal DataIn, DataOut : unsigned(Nbits_data-1 downto 0);
  signal WE : Std_logic;
  signal clock : Std_logic;
  signal StopClock : boolean := FALSE;

  signal ok: boolean := true;

  constant ALL_Z : std_logic_vector(Nbits_data-1 downto 0) := (others => 'Z');

  -- Word written at address i: the address folded on the data width with xor, so
  -- that the RAM number (address MSBs) changes the data too. With data = address
  -- truncated to the data width, a quadram writing all its RAMs at once could pass.
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
  generic map (
    N          => N,
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

    -- write to all addresses, i.e. to every RAM
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

    -- N not a power of 2: the first address after the last RAM selects nothing
    if NWORDS < 2**Nbits then
      address <= to_unsigned(NWORDS, Nbits);
      wait until falling_edge(clock);
      check(std_logic_vector(dataout) = ALL_Z, "address " & integer'image(NWORDS)
            & " (no RAM): dataout = " & to_str(dataout) & ", expected high impedance");
    end if;

    if errors = 0 then
      report "Bench2 OK: " & integer'image(N) & " RAMs of " & integer'image(2**Nbits_addr)
           & " words of " & integer'image(Nbits_data) & " bits written and read back";
    else
      report "Bench2 FAILED: " & integer'image(errors) & " errors" severity error;
    end if;

    StopClock <= true;
    wait;
  end process;

end architecture Bench2;
