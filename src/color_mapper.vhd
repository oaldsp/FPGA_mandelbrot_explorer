library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity color_mapper is
    generic(
        MAX_ITERATIONS : unsigned(7 downto 0) := x"FF" -- Valor 255
    );
    port(
        iteration_count : in  unsigned(7 downto 0);
        pixel_color     : out std_logic_vector(8 downto 0)
    );
end color_mapper;

architecture combinational of color_mapper is
    signal red_chan   : unsigned(2 downto 0);
    signal green_chan : unsigned(2 downto 0);
    signal blue_chan  : unsigned(2 downto 0);
    signal iter_index : integer range 0 to 255;
begin

    iter_index <= to_integer(iteration_count);

    process(iter_index)
    begin
        -- Caso padrão (evita latches)
        red_chan   <= "000";
        green_chan <= "111";
        blue_chan  <= "000";

        case iter_index is
            -- Se atingiu o máximo de iterações, pertence ao conjunto (Preto)
            when 255 =>
                red_chan   <= "000";
                green_chan <= "000";
                blue_chan  <= "111";

            -- Gradiente dinâmico para as outras iterações (0 a 254)
            when 0 to 31 =>
                red_chan   <= "000";
                green_chan <= "000";
                blue_chan  <= to_unsigned(iter_index / 4, 3); -- Azul subindo
                
            when 32 to 63 =>
                red_chan   <= "000";
                green_chan <= to_unsigned((iter_index - 32) / 4, 3); -- Verde subindo
                blue_chan  <= "111"; -- Azul no máximo
                
            when 64 to 127 =>
                red_chan   <= to_unsigned((iter_index - 64) / 8, 3); -- Vermelho subindo suave
                green_chan <= "111";
                blue_chan  <= "111" - to_unsigned((iter_index - 64) / 10, 3); -- Azul descendo
                
            when 128 to 191 =>
                red_chan   <= "111";
                green_chan <= "111" - to_unsigned((iter_index - 128) / 8, 3); -- Verde descendo
                blue_chan  <= "000";
                
            when 192 to 254 =>
                red_chan   <= "111" - to_unsigned((iter_index - 192) / 10, 3); -- Vermelho descendo
                green_chan <= "000";
                blue_chan  <= to_unsigned((iter_index - 192) / 10, 3); -- Azul subindo leve
                
            when others =>
                red_chan   <= "111";
                green_chan <= "000";
                blue_chan  <= "000";
        end case;
    end process;

    -- Agrupa os canais de 3 bits no barramento final de 9 bits [R, G, B]
    pixel_color <= std_logic_vector(red_chan) & std_logic_vector(green_chan) & std_logic_vector(blue_chan);

end combinational;