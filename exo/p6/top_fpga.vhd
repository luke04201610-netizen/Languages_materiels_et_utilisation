-- Top level for the ALIENTEK "New Starter" (Xinqidian) board, EP4CE10F17C8, part 6.
-- Port names and pins follow the pin table of the board.
--   - the system runs at 50 MHz / 2**DIV_LOG2 (3.125 MHz): the combinational
--     divider of the processor is too slow for 50 MHz;
--   - the 6-digit display shows a register in decimal: x24 by default,
--     x20 to x23 while KEY0 to KEY3 is pressed;
--   - LED0: ebreak reached, LED1: unknown instruction, LED3: blinks while the clock runs.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity top_fpga is
  generic (
    PROG_FILE : string   := "test_memoire.txt";
    DIV_LOG2  : positive := 4                      -- keep top_fpga.sdc consistent
  );
  port (
    sys_clk   : in  std_logic;                     -- 50 MHz
    sys_rst_n : in  std_logic;                     -- RESET button, active low
    key       : in  std_logic_vector(3 downto 0);  -- KEY0 to KEY3, active low
    led       : out std_logic_vector(3 downto 0);  -- active high
    sel       : out std_logic_vector(5 downto 0);  -- digit select, active low
    seg_led   : out std_logic_vector(7 downto 0)   -- segments, active low
  );
end entity top_fpga;

architecture struct of top_fpga is

  signal div       : unsigned(DIV_LOG2-1 downto 0) := (others => '0');
  signal clock     : std_logic;
  signal rst_sync  : std_logic_vector(1 downto 0) := "11";  -- reset at power-up
  signal reset     : std_logic;
  signal key_sync  : std_logic_vector(3 downto 0) := (others => '1');
  signal show_reg  : std_logic_vector(4 downto 0);
  signal result    : std_logic_vector(31 downto 0);
  signal halted    : std_logic;
  signal illegal   : std_logic;
  signal heartbeat : unsigned(20 downto 0) := (others => '0');

begin

  -- system clock: 50 MHz divided by 2**DIV_LOG2
  DivProc: process(sys_clk) is
  begin
    if rising_edge(sys_clk) then
      div <= div + 1;
    end if;
  end process DivProc;
  clock <= div(DIV_LOG2-1);

  -- button and keys resynchronised on the system clock
  SyncProc: process(clock) is
  begin
    if rising_edge(clock) then
      rst_sync  <= rst_sync(0) & not sys_rst_n;
      key_sync  <= key;
      heartbeat <= heartbeat + 1;
    end if;
  end process SyncProc;
  reset <= rst_sync(1);

  show_reg <= "10100" when key_sync(0) = '0' else   -- x20
              "10101" when key_sync(1) = '0' else   -- x21
              "10110" when key_sync(2) = '0' else   -- x22
              "10111" when key_sync(3) = '0' else   -- x23
              "11000";                              -- x24

  SYS: entity work.systeme_fpga
    generic map (PROG_FILE => PROG_FILE)
    port map (
      clock    => clock,
      reset    => reset,
      show_reg => show_reg,
      result   => result,
      halted   => halted,
      illegal  => illegal
    );

  DISP: entity work.seg_display
    port map (clock => clock, value => result, sel => sel, seg_led => seg_led);

  led(0) <= halted;
  led(1) <= illegal;
  led(2) <= '0';
  led(3) <= heartbeat(heartbeat'high);

end architecture struct;
