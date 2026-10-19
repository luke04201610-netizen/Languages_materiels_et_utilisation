-- Simple generic RAM Model
--
-- +-----------------------------+
-- |    Copyright 2008 DOULOS    |
-- |   designer :  JK            |
-- +-----------------------------+
--
-- Q2: std_logic_vector replaced by unsigned (IEEE.Numeric_Std)
-- Q4: generic on the data width (Nbits_data) and on the number of words (2**Nbits_addr)

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity sync_ram is
  generic (
    Nbits_addr : positive := 10;  -- address width: the RAM stores 2**Nbits_addr words
    Nbits_data : positive := 8    -- data width
  );
  port (
    clock   : in  std_logic;
    we      : in  std_logic;
    address : in  unsigned(Nbits_addr-1 downto 0);
    datain  : in  unsigned(Nbits_data-1 downto 0);
    dataout : out unsigned(Nbits_data-1 downto 0)
  );
end entity sync_ram;

architecture RTL of sync_ram is

   -- the sizes come from the ports ('length, 'range), so they follow the generics
   type ram_type is array (0 to (2**address'length)-1) of unsigned(datain'range);
   signal ram : ram_type;
   signal read_address : unsigned(address'range);

begin

  RamProc: process(clock) is

  begin
    if rising_edge(clock) then
      if we = '1' then
        ram(to_integer(address)) <= datain;
      end if;
      read_address <= address;
    end if;
  end process RamProc;

  dataout <= ram(to_integer(read_address));

end architecture RTL;
