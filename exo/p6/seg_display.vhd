-- Decimal display of a 32-bit signed value on the 6 digits of the board
-- (common anode: segments and digit selects active low, as in the board examples).
-- The digits are scanned one after the other, each one during 2**SCAN_LOG2 periods.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity seg_display is
  generic (
    SCAN_LOG2 : positive := 12                    -- 4096 periods of 3.125 MHz = 1.3 ms per digit
  );
  port (
    clock   : in  std_logic;
    value   : in  std_logic_vector(31 downto 0);  -- signed value to display
    sel     : out std_logic_vector(5 downto 0);   -- digit select, sel(0) = rightmost digit
    seg_led : out std_logic_vector(7 downto 0)    -- dp & g f e d c b a
  );
end entity seg_display;

architecture RTL of seg_display is

  -- binary to BCD conversion (double dabble): 6 decimal digits
  function to_bcd(bin : unsigned(19 downto 0)) return unsigned is
    variable bcd : unsigned(23 downto 0) := (others => '0');
  begin
    for i in 19 downto 0 loop
      for d in 0 to 5 loop
        if bcd(4*d+3 downto 4*d) > 4 then
          bcd(4*d+3 downto 4*d) := bcd(4*d+3 downto 4*d) + 3;
        end if;
      end loop;
      bcd := bcd(22 downto 0) & bin(i);
    end loop;
    return bcd;
  end function to_bcd;

  -- segments g f e d c b a, active low
  function segments(digit : unsigned(3 downto 0)) return std_logic_vector is
  begin
    case to_integer(digit) is
      when 0      => return "1000000";
      when 1      => return "1111001";
      when 2      => return "0100100";
      when 3      => return "0110000";
      when 4      => return "0011001";
      when 5      => return "0010010";
      when 6      => return "0000010";
      when 7      => return "1111000";
      when 8      => return "0000000";
      when 9      => return "0010000";
      when 11     => return "0111111";            -- minus sign
      when others => return "1111111";            -- blank
    end case;
  end function segments;

  signal negative  : std_logic;
  signal magnitude : unsigned(31 downto 0);
  signal bcd       : unsigned(23 downto 0);
  signal scan      : unsigned(SCAN_LOG2-1 downto 0) := (others => '0');
  signal digit_idx : integer range 0 to 5 := 0;

begin

  negative  <= value(31);
  magnitude <= unsigned(value) when value(31) = '0' else unsigned(-signed(value));
  bcd       <= to_bcd(magnitude(19 downto 0));

  ScanProc: process(clock) is
  begin
    if rising_edge(clock) then
      scan <= scan + 1;
      if scan = 0 then
        if digit_idx = 5 then
          digit_idx <= 0;
        else
          digit_idx <= digit_idx + 1;
        end if;
      end if;
    end if;
  end process ScanProc;

  DisplayProc: process(digit_idx, bcd, negative) is
    variable code    : unsigned(3 downto 0);
    variable leading : boolean;   -- true while only zeros are on the left of the digit
  begin
    -- blank the zeros on the left of the number, but keep the units digit
    leading := true;
    for d in 5 downto 1 loop
      if d >= digit_idx and bcd(4*d+3 downto 4*d) /= 0 then
        leading := false;
      end if;
    end loop;
    code := resize(shift_right(bcd, 4*digit_idx), 4);
    if digit_idx > 0 and leading then
      code := to_unsigned(10, 4);                 -- blank
    end if;
    if digit_idx = 5 and negative = '1' then
      code := to_unsigned(11, 4);                 -- minus sign on the leftmost digit
    end if;
    sel            <= (others => '1');
    sel(digit_idx) <= '0';
    seg_led        <= '1' & segments(code);       -- decimal point off
  end process DisplayProc;

end architecture RTL;
