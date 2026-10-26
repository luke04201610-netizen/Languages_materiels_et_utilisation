library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity quadram is
  generic (
    Nbits_sel  : positive := 2;   
    Nbits_addr : positive := 8;   
    Nbits_data : positive := 8   
  );
  port (
    clock   : in  std_logic;
    we      : in  std_logic;
    address : in  unsigned(Nbits_sel+Nbits_addr-1 downto 0);  
    datain  : in  unsigned(Nbits_data-1 downto 0);
    dataout : out unsigned(Nbits_data-1 downto 0)
  );
end entity quadram;

architecture RTL of quadram is
  signal cs : std_logic_vector(2**Nbits_sel-1 downto 0);   
begin

  DEC: entity work.decoder(RTL)
    generic map (Nbits_sel => Nbits_sel)
    port map (
      data_in => address(address'high downto Nbits_addr),
      cs_out  => cs
    );

  RAMS: for i in 0 to 2**Nbits_sel-1 generate
    RAM: entity work.sync_ram(RTL)
      generic map (Nbits_addr => Nbits_addr, Nbits_data => Nbits_data)
      port map (cs => cs(i), clock => clock, we => we,
                address => address(Nbits_addr-1 downto 0),
                datain => datain, dataout => dataout);
  end generate RAMS;

end architecture RTL;