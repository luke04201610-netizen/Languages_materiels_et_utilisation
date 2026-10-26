library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity decoder is
  generic (
    Nbits_sel : positive := 2                                  
  );
  port (
    data_in : in  unsigned(Nbits_sel-1 downto 0);              
    cs_out  : out std_logic_vector(2**Nbits_sel-1 downto 0)    
  );
end entity decoder;

architecture RTL of decoder is
begin

  GEN_CS: for i in 0 to 2**Nbits_sel-1 generate
    cs_out(i) <= '1' when data_in = i else '0';
  end generate GEN_CS;

end architecture RTL;