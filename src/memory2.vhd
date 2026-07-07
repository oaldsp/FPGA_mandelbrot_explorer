library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory2 is
    port (
        clock     : in std_logic := '1';
        data      : in std_logic_vector (8 downto 0);
        wraddress : in std_logic_vector (19 downto 0);
        rdaddress : in std_logic_vector (19 downto 0);
        wren      : in std_logic := '0';
        q         : out std_logic_vector (8 downto 0)
    );
end memory2;

architecture rtl of memory2 is
    -- Aloca espaço correto para o Frame Buffer
    type ram_type is array (0 to 307200) of std_logic_vector(8 downto 0);
    signal ram_block : ram_type := (others => (others => '0'));
begin

    process(clock)
    begin
        if rising_edge(clock) then
            -- Canal de Escrita (Porta A) - Só escreve se o controlador mandar
            if wren = '1' then
                ram_block(to_integer(unsigned(wraddress))) <= data;
            end if;
            
            -- Canal de Leitura (Porta B) - LÊ SEMPRE no ritmo do clock
            q <= ram_block(to_integer(unsigned(rdaddress)));
				/*if rdaddress <= "00000000000000111111" then
					q <= "000000111"; -- Azul
				elsif rdaddress <= "0000000111111111111" then
					q <= "000111000"; -- Verde
				else
					q <= "111000000"; -- Vermelho
				end if;*/
        end if;
    end process;

end architecture;