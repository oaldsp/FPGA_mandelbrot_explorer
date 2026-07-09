library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity color_mapper is
    generic(
        MAX_ITERATIONS : unsigned(7 downto 0) := x"FF" -- Valor 255
    );
    port(
        iteration_count : in  unsigned(7 downto 0);
        pixel_color     : out std_logic_vector(11 downto 0) -- 12 bits (4 para cada: R, G, B)
    );
end color_mapper;

architecture combinational of color_mapper is
    signal red_chan   : unsigned(3 downto 0);
    signal green_chan : unsigned(3 downto 0);
    signal blue_chan  : unsigned(3 downto 0);
    signal iter_index : integer range 0 to 255;
begin

    iter_index <= to_integer(iteration_count);
    
    process(iter_index)
    begin
        -- Caso padrão
        red_chan   <= "0000";
        green_chan <= "1111";
        blue_chan  <= "0000";

        case iter_index is
            -- Se atingiu o máximo de iterações, pertence ao conjunto
            when 255 =>
                red_chan   <= "0000";
                green_chan <= "0000";
                blue_chan  <= "1111";

            -- Gradiente dinâmico para as outras iterações (0 a 254)
            when 0 to 31 =>
                red_chan   <= "0000";
                green_chan <= "0000";
                blue_chan  <= to_unsigned(iter_index / 2, 4);        -- Azul subindo (max 31/2 = 15)
                
            when 32 to 63 =>
                red_chan   <= "0000";
                green_chan <= to_unsigned((iter_index - 32) / 2, 4); -- Verde subindo (max 31/2 = 15)
                blue_chan  <= "1111";                                -- Azul no máximo
                
            when 64 to 127 =>
                red_chan   <= to_unsigned((iter_index - 64) / 4, 4); -- Vermelho subindo suave (max 63/4 = 15)
                green_chan <= "1111";
                blue_chan  <= "1111" - to_unsigned((iter_index - 64) / 4, 4); -- Azul descendo (max 63/4 = 15)
                
            when 128 to 191 =>
                red_chan   <= "1111";
                green_chan <= "1111" - to_unsigned((iter_index - 128) / 4, 4); -- Verde descendo (max 63/4 = 15)
                blue_chan  <= "0000";
                
            when 192 to 254 =>
                red_chan   <= "1111" - to_unsigned((iter_index - 192) / 4, 4); -- Vermelho descendo (max 62/4 = 15)
                green_chan <= "0000";
                blue_chan  <= to_unsigned((iter_index - 192) / 4, 4);          -- Azul subindo leve
                
            when others =>
                red_chan   <= "1111";
                green_chan <= "0000";
                blue_chan  <= "0000";
        end case;
    end process;

    -- Agrupa os canais de 4 bits no barramento final de 12 bits [R, G, B]
    pixel_color <= std_logic_vector(red_chan) & std_logic_vector(green_chan) & std_logic_vector(blue_chan);

end combinational;