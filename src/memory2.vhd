library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory2 is
    port (
        clock     : in std_logic := '1';
        data      : in std_logic_vector (7 downto 0);
        wraddress : in std_logic_vector (16 downto 0);
        rdaddress : in std_logic_vector (16 downto 0);
        wren      : in std_logic := '0';
        q         : out std_logic_vector (7 downto 0)
    );
end memory2;

architecture rtl of memory2 is
    type ram_type is array (0 to 307199) of std_logic_vector(7 downto 0);
    signal ram_block : ram_type;

    -- Atributo de síntese para forçar o compilador a usar Block RAM dedicadas da FPGA
    -- em vez de registradores comuns (o que causava o estouro de 188%)
    attribute ramstyle : string;
    attribute ramstyle of ram_block : signal is "no_rw_check";
begin

    process(clock)
    begin
        if rising_edge(clock) then
            -- Canal de Escrita (Porta A)
            if wren = '1' then
                ram_block(to_integer(unsigned(wraddress))) <= data;
            end if;
            
            -- Canal de Leitura (Porta B)
            q <= ram_block(to_integer(unsigned(rdaddress)));
        end if;
    end process;

end architecture;