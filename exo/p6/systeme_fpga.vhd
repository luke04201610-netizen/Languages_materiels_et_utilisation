-- System of part 5 with the synthesizable processor (part 6).
-- The quadram block is reused without any change; only the processor is replaced
-- by riscvproc_fpga.v. The board itself (clock, button, display) is handled by
-- the top level of the board.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity systeme_fpga is
  generic (
    PROG_FILE : string := "test_memoire.txt"     -- program loaded into the processor ROM
  );
  port (
    clock    : in  std_logic;
    reset    : in  std_logic;                     -- synchronous, active high
    show_reg : in  std_logic_vector(4 downto 0);  -- register sent to 'result'
    result   : out std_logic_vector(31 downto 0); -- value of register show_reg
    halted   : out std_logic;                     -- the program has reached ebreak
    illegal  : out std_logic                      -- an unknown instruction was skipped
  );
end entity systeme_fpga;

architecture struct of systeme_fpga is

  component riscvproc_fpga is
    generic (
      PROG_FILE : string  := "test_memoire.txt";
      ROM_AW    : integer := 8
    );
    port (
      clock       : in  std_logic;
      reset       : in  std_logic;
      address     : out std_logic_vector(11 downto 0);
      dataToWrite : out std_logic_vector(31 downto 0);
      dataToRead  : in  std_logic_vector(31 downto 0);
      we          : out std_logic;
      dbg_sel     : in  std_logic_vector(4 downto 0);
      dbg_reg     : out std_logic_vector(31 downto 0);
      halted      : out std_logic;
      illegal     : out std_logic
    );
  end component riscvproc_fpga;

  signal address     : std_logic_vector(11 downto 0);
  signal dataToWrite : std_logic_vector(31 downto 0);
  signal dataToRead  : std_logic_vector(31 downto 0);
  signal we          : std_logic;
  signal dataOut     : unsigned(31 downto 0);

begin

  CPU: riscvproc_fpga
    generic map (PROG_FILE => PROG_FILE, ROM_AW => 8)
    port map (
      clock       => clock,
      reset       => reset,
      address     => address,
      dataToWrite => dataToWrite,
      dataToRead  => dataToRead,
      we          => we,
      dbg_sel     => show_reg,
      dbg_reg     => result,
      halted      => halted,
      illegal     => illegal
    );

  -- 4 RAMs of 1024 words of 32 bits, same instance as in exo/p5/systeme.vhd
  MEM: entity work.quadram(RTL)
    generic map (Nbits_sel => 2, Nbits_addr => 10, Nbits_data => 32)
    port map (
      clock   => clock,
      we      => we,
      address => unsigned(address),
      datain  => unsigned(dataToWrite),
      dataout => dataOut
    );

  dataToRead <= std_logic_vector(dataOut);

end architecture struct;
