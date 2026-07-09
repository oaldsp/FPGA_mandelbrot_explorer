library IEEE;
use  IEEE.STD_LOGIC_1164.all;
USE ieee.numeric_std.all;

entity enderecamento2 is
   port( 
      clock		:	in std_logic;
		coluna,Linha : in std_logic_vector(9 downto 0);
		address: out std_logic_vector(16 downto 0)
	);
end entity enderecamento2;

architecture comportamento of enderecamento2 is	

constant maxcol : integer  := 320;
signal auxadd :  INTEGER RANGE 0 to 80000 ;--
signal auxlinha:	INTEGER RANGE 0 to 1023;--
signal auxcoluna:	INTEGER RANGE 0 to 1023 ;--
begin
		process(clock)
		variable aux :  INTEGER RANGE 0 to 319 := 0;--
		begin
			
			if (clock'event and clock = '1') then
			auxlinha <= to_integer(unsigned(linha));
			auxcoluna <= to_integer(unsigned(coluna));
			auxadd <=  ((480-auxlinha))*320+auxcoluna;
			address <=  std_logic_vector(to_unsigned(auxadd,17));
			end if;
		
		end process;
		--	

end comportamento;
