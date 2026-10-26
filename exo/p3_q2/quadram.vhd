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
      data_in => address(9 downto 8),
      cs_out  => cs
    );

  RAM0: entity work.sync_ram(RTL)
    generic map (Nbits_addr => 8, Nbits_data => 8)
    port map (  
                cs => cs(0), 
                clock => clock, we => we,
                address => address(7 downto 0), 
                datain => datain, dataout => dataout);

  RAM1: entity work.sync_ram(RTL)
    generic map (Nbits_addr => 8, Nbits_data => 8)
    port map (  
                cs => cs(1), 
                clock => clock, we => we,
                address => address(7 downto 0), 
                datain => datain, dataout => dataout);

  RAM2: entity work.sync_ram(RTL)
    generic map (Nbits_addr => 8, Nbits_data => 8)
    port map (  
                cs => cs(2), 
                clock => clock, we => we,
                address => address(7 downto 0), 
                datain => datain, dataout => dataout);

  RAM3: entity work.sync_ram(RTL)
    generic map (Nbits_addr => 8, Nbits_data => 8)
    port map (  
                cs => cs(3), 
                clock => clock, we => we,
                address => address(7 downto 0), 
                datain => datain, dataout => dataout);

end architecture RTL;