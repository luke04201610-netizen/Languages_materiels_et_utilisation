library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity decoder is
  port (
    data_in : in  unsigned(1 downto 0);         
    cs_out  : out std_logic_vector(3 downto 0)  
  );
end entity decoder;

architecture RTL of decoder is
begin
  with data_in select
    cs_out <= "0001" when "00",
              "0010" when "01",
              "0100" when "10",
              "1000" when "11",
              "0000" when others;   
end architecture RTL;