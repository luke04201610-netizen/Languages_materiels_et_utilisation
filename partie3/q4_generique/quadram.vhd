-- Generic memory made of N sync_ram (Q4), generalisation of figure 2:
--   address MSBs (log2ceil(N) bits): number of the RAM, decoded into the chip selects
--   address LSBs (Nbits_addr bits) : address inside the RAM
-- The N RAMs share clock, we, address and datain, and they all drive dataout:
-- only the selected one puts its word on it, the others are in high impedance.
-- N needs not be a power of 2: the addresses after the last RAM select no RAM
-- (writes ignored, dataout in high impedance).

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;
use work.util_pkg.all;

entity quadram is
  generic (
    N          : positive := 4;   -- number of sync_ram, at least 2
    Nbits_addr : positive := 8;   -- address width of one sync_ram
    Nbits_data : positive := 8    -- data width
  );
  port (
    clock   : in  std_logic;
    we      : in  std_logic;
    address : in  unsigned(log2ceil(N) + Nbits_addr - 1 downto 0);
    datain  : in  unsigned(Nbits_data-1 downto 0);
    dataout : out unsigned(Nbits_data-1 downto 0)
  );
end entity quadram;

architecture RTL of quadram is

  constant Nbits_sel : positive := log2ceil(N);  -- inputs of the decoder

  signal cs : std_logic_vector(2**Nbits_sel-1 downto 0);

begin

  DEC: entity work.decoder(RTL)
  generic map (
    Nbits_in => Nbits_sel
  )
  port map (
    sel => address(address'high downto Nbits_addr),
    cs  => cs
  );

  RAMS: for i in 0 to N-1 generate
    RAM: entity work.sync_ram(RTL)
    generic map (
      Nbits_addr => Nbits_addr,
      Nbits_data => Nbits_data
    )
    port map (
      clock   => clock,
      cs      => cs(i),
      we      => we,
      address => address(Nbits_addr-1 downto 0),
      datain  => datain,
      dataout => dataout
    );
  end generate RAMS;

end architecture RTL;
