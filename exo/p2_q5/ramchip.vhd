-- Simple generic RAM Model
--
-- +-----------------------------+
-- |    Copyright 2008 DOULOS    |
-- |   designer :  JK            |
-- +-----------------------------+

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.Numeric_Std.all;

entity sync_ram is
  generic (
    Nbits_addr : natural := 10;
    Nbits_data : natural := 8
  );
  port (
    cs      : in  std_logic;
    clock   : in  std_logic;
    we      : in  std_logic;
    address : in  unsigned(Nbits_addr-1 downto 0);
    datain  : in  unsigned(Nbits_data-1 downto 0);
    dataout : out unsigned(Nbits_data-1 downto 0)
  );
end entity sync_ram;

architecture RTL of sync_ram is

   type ram_type is array (0 to (2**address'length)-1) of unsigned(datain'range);
   signal ram : ram_type;
   signal read_address :unsigned(address'range);

begin

  RamProc: process(clock) is

  begin
    if rising_edge(clock) then
      if we = '1' and cs = '1' then
        ram(to_integer(address)) <= datain;
      end if;
      read_address <= address;
    end if;
  end process RamProc;

dataout <= ram(to_integer(read_address)) when cs = '1' else (others => 'Z');
end architecture RTL;
