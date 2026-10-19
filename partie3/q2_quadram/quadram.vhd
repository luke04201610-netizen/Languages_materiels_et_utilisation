-- Memory made of 4 sync_ram (Q2), as in figure 2:
--   address(9 downto 8): number of the RAM, decoded into the chip selects cs(3 downto 0)
--   address(7 downto 0): address inside the RAM
-- The 4 RAMs share clock, we, address and datain, and they all drive dataout:
-- only the selected one puts its word on it, the others are in high impedance.

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity quadram is
  port (
    clock   : in  std_logic;
    we      : in  std_logic;
    address : in  unsigned(9 downto 0);
    datain  : in  unsigned(7 downto 0);
    dataout : out unsigned(7 downto 0)
  );
end entity quadram;

architecture RTL of quadram is

  signal cs : std_logic_vector(3 downto 0);

begin

  DEC: entity work.decoder(RTL)
  port map (
    sel => address(9 downto 8),
    cs  => cs
  );

  RAM0: entity work.sync_ram(RTL)
  generic map (
    Nbits_addr => 8,
    Nbits_data => 8
  )
  port map (
    clock   => clock,
    cs      => cs(0),
    we      => we,
    address => address(7 downto 0),
    datain  => datain,
    dataout => dataout
  );

  RAM1: entity work.sync_ram(RTL)
  generic map (
    Nbits_addr => 8,
    Nbits_data => 8
  )
  port map (
    clock   => clock,
    cs      => cs(1),
    we      => we,
    address => address(7 downto 0),
    datain  => datain,
    dataout => dataout
  );

  RAM2: entity work.sync_ram(RTL)
  generic map (
    Nbits_addr => 8,
    Nbits_data => 8
  )
  port map (
    clock   => clock,
    cs      => cs(2),
    we      => we,
    address => address(7 downto 0),
    datain  => datain,
    dataout => dataout
  );

  RAM3: entity work.sync_ram(RTL)
  generic map (
    Nbits_addr => 8,
    Nbits_data => 8
  )
  port map (
    clock   => clock,
    cs      => cs(3),
    we      => we,
    address => address(7 downto 0),
    datain  => datain,
    dataout => dataout
  );

end architecture RTL;
