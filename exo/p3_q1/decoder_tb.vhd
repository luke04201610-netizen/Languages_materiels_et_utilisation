library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity decoder_tb is
end entity decoder_tb;

architecture bench of decoder_tb is

  signal data_in : unsigned(1 downto 0);          
  signal cs_out  : std_logic_vector(3 downto 0);

begin

  UUT: entity work.decoder(RTL)                   
  port map (
    data_in => data_in,
    cs_out  => cs_out
  );

  Stim: process is                                
  begin
    data_in <= "00";
    wait for 10 ns;
    assert cs_out = "0001" report "data_in = 00 : cs_out faux" severity error;

    data_in <= "01";
    wait for 10 ns;
    assert cs_out = "0010" report "data_in = 01 : cs_out faux" severity error;

    data_in <= "10";
    wait for 10 ns;
    assert cs_out = "0100" report "data_in = 10 : cs_out faux" severity error;

    data_in <= "11";
    wait for 10 ns;
    assert cs_out = "1000" report "data_in = 11 : cs_out faux" severity error;

    data_in <= "XX";
    wait for 10 ns;
    assert cs_out = "0000" report "data_in = XX : une RAM est selectionnee" severity error;

    report "Fin du test du decodeur";
    wait;                                         
  end process Stim;

end architecture bench;