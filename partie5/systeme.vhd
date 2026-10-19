-- Complete system (partie 5, figure 4): the RISC-V processor (Verilog module
-- riscvproc, instantiated as a component) and the generic quadram (VHDL), where
-- the processor stores its data. The program stays inside the processor.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity systeme is
  port (
    clock : in std_logic;
    reset : in std_logic
  );
end entity systeme;

architecture struct of systeme is

  -- Verilog module riscvproc (riscvproc.sv): same name, same ports
  component riscvproc is
    port (
      clock       : in  std_logic;
      reset       : in  std_logic;
      address     : out std_logic_vector(11 downto 0);
      dataToWrite : out std_logic_vector(31 downto 0);
      dataToRead  : in  std_logic_vector(31 downto 0);
      we          : out std_logic
    );
  end component riscvproc;

  -- bus between the processor and the quadram
  signal address     : std_logic_vector(11 downto 0);
  signal dataToWrite : std_logic_vector(31 downto 0);
  signal dataToRead  : std_logic_vector(31 downto 0);
  signal we          : std_logic;
  signal dataOut     : unsigned(31 downto 0);

begin

  CPU: riscvproc
  port map (
    clock       => clock,
    reset       => reset,
    address     => address,
    dataToWrite => dataToWrite,
    dataToRead  => dataToRead,
    we          => we
  );

  -- 4 RAMs of 1024 words of 32 bits: address(11 downto 10) selects the RAM,
  -- address(9 downto 0) is the word inside the RAM
  MEM: entity work.quadram(RTL)
  generic map (
    N          => 4,
    Nbits_addr => 10,
    Nbits_data => 32
  )
  port map (
    clock   => clock,
    we      => we,
    address => unsigned(address),
    datain  => unsigned(dataToWrite),
    dataout => dataOut
  );

  -- the quadram works with unsigned, the processor with std_logic_vector
  dataToRead <= std_logic_vector(dataOut);

end architecture struct;
