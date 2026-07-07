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
    -- Sinais internos para os canais de cores (3 bits cada)
    signal red_chan   : unsigned(2 downto 0);
    signal green_chan : unsigned(2 downto 0);
    signal blue_chan  : unsigned(2 downto 0);
    
    -- Sinal para truncar/ajustar a faixa interna de iterações (0 a 254)
    signal iter_index : integer range 0 to 255;
begin

    -- Converte para inteiro para facilitar as comparações de faixa (ranges)
    iter_index <= to_integer(iteration_count);

    -- Processo puramente combinacional para mapeamento do gradiente
    process(iter_index, iteration_count)
    begin
        -- Caso padrão: Inicializa tudo em zero (Preto)
        red_chan   <= "000";
        green_chan <= "000";
        blue_chan  <= "000";

        -- Regra 1: Se atingiu o máximo de iterações, o pixel pertence ao conjunto (Preto)
        if iteration_count = MAX_ITERATIONS then
            red_chan   <= "000";
            green_chan <= "000";
            blue_chan  <= "000";
        else
            -- Regra 2: Criação do gradiente cíclico/suave dividido em 8 bandas de frequência
            -- Usamos os 3 bits menos significativos ou mapeamento direto para suavizar as transições
            case iter_index is
                -- Fase 1: Azul Escuro -> Azul Claro / Ciano
                when 0 to 31 =>
                    red_chan   <= "000";
                    green_chan <= to_unsigned((iter_index / 4), 3); -- Verde subindo
                    blue_chan  <= "100" + to_unsigned((iter_index / 8), 3); -- Azul brilhando

                -- Fase 2: Ciano -> Verde
                when 32 to 63 =>
                    red_chan   <= "000";
                    green_chan <= "111";
                    blue_chan  <= "111" - to_unsigned(((iter_index - 32) / 4), 3); -- Azul descendo

                -- Fase 3: Verde -> Amarelo
                when 64 to 95 =>
                    red_chan   <= to_unsigned(((iter_index - 64) / 4), 3); -- Vermelho subindo
                    green_chan <= "111";
                    blue_chan  <= "000";

                -- Fase 4: Amarelo -> Laranja / Vermelho
                when 96 to 127 =>
                    red_chan   <= "111";
                    green_chan <= "111" - to_unsigned(((iter_index - 96) / 4), 3); -- Verde descendo
                    blue_chan  <= "000";

                -- Fase 5: Vermelho -> Magenta
                when 128 to 159 =>
                    red_chan   <= "111";
                    green_chan <= "000";
                    blue_chan  <= to_unsigned(((iter_index - 128) / 4), 3); -- Azul subindo

                -- Fase 6: Magenta -> Azul Escuro de Alta Iteração
                when 160 to 191 =>
                    red_chan   <= "111" - to_unsigned(((iter_index - 160) / 4), 3); -- Vermelho descendo
                    green_chan <= "000";
                    blue_chan  <= "111";

                -- Fase 7: Azul de Alta Iteração -> Ciano Claro
                when 192 to 223 =>
                    red_chan   <= to_unsigned(((iter_index - 192) / 8), 3); -- Vermelho sobe de leve
                    green_chan <= to_unsigned(((iter_index - 192) / 4), 3); -- Verde subindo
                    blue_chan  <= "111";

                -- Fase 8: Ciano Claro -> Branco/Suave antes do Preto do corpo
                when 224 to 254 =>
                    red_chan   <= "011" + to_unsigned(((iter_index - 224) / 8), 3);
                    green_chan <= "111";
                    blue_chan  <= "111" - to_unsigned(((iter_index - 224) / 8), 3);
                    
                when others =>
                    red_chan   <= "000";
                    green_chan <= "000";
                    blue_chan  <= "000";
            end case;
        end if;
    end process;

    -- Agrupa os canais individuais na saída RGB de 9 bits
    -- bits [8:6] = Vermelho, bits [5:3] = Verde, bits [2:0] = Azul
    pixel_color <= std_logic_vector(red_chan) & std_logic_vector(green_chan) & std_logic_vector(blue_chan);

end combinational;