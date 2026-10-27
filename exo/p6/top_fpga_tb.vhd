-- Testbench of the board top level: reads the 6 digits of the display as the board
-- would show them, first without key (x24), then with KEY0 pressed (x20).

library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity top_fpga_tb is
end entity top_fpga_tb;

architecture Bench of top_fpga_tb is
  signal sys_clk   : std_logic := '0';
  signal sys_rst_n : std_logic := '0';
  signal key       : std_logic_vector(3 downto 0) := "1111";
  signal led       : std_logic_vector(3 downto 0);
  signal sel       : std_logic_vector(5 downto 0);
  signal seg_led   : std_logic_vector(7 downto 0);

  -- character shown by the segments g f e d c b a (active low)
  function decode(s : std_logic_vector(6 downto 0)) return character is
  begin
    case s is
      when "1000000" => return '0';
      when "1111001" => return '1';
      when "0100100" => return '2';
      when "0110000" => return '3';
      when "0011001" => return '4';
      when "0010010" => return '5';
      when "0000010" => return '6';
      when "1111000" => return '7';
      when "0000000" => return '8';
      when "0010000" => return '9';
      when "0111111" => return '-';
      when "1111111" => return ' ';
      when others    => return '?';
    end case;
  end function decode;

  -- reads one full scan of the six digits, leftmost digit first
  procedure read_display(signal sel : in std_logic_vector(5 downto 0);
                         signal seg : in std_logic_vector(7 downto 0);
                         txt : out string(1 to 6)) is
  begin
    for n in 1 to 6 loop
      wait on sel;
      wait for 1 ns;
      for i in 0 to 5 loop
        if sel(i) = '0' then
          txt(6 - i) := decode(seg(6 downto 0));
        end if;
      end loop;
    end loop;
  end procedure read_display;

begin

  -- DIV_LOG2 = 1: 25 MHz system clock to shorten the simulation
  UUT: entity work.top_fpga
    generic map (PROG_FILE => "test_memoire.txt", DIV_LOG2 => 1)
    port map (sys_clk => sys_clk, sys_rst_n => sys_rst_n, key => key,
              led => led, sel => sel, seg_led => seg_led);

  sys_clk   <= not sys_clk after 10 ns;              -- 50 MHz
  sys_rst_n <= '0', '1' after 200 ns;

  Check: process is
    variable txt : string(1 to 6);
  begin
    wait for 50 us;                                  -- the program has finished
    read_display(sel, seg_led, txt);
    report "Sans touche (x24) : [" & txt & "], LED0 = " & std_logic'image(led(0))
           & ", LED1 = " & std_logic'image(led(1));
    key(0) <= '0';                                   -- KEY0 pressed: x20
    wait for 50 us;
    read_display(sel, seg_led, txt);
    report "KEY0 (x20) : [" & txt & "]";
    key(0) <= '1';
    key(3) <= '0';                                   -- KEY3 pressed: x23
    wait for 50 us;
    read_display(sel, seg_led, txt);
    report "KEY3 (x23) : [" & txt & "]";
    wait;
  end process Check;

end architecture Bench;
