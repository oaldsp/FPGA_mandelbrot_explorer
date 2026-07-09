-- Converte coordenadas da tela em coordenadas do plano complexo.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity coordinate_generator is
	generic(
		SCREEN_WIDTH  : integer := 640;
		SCREEN_HEIGHT : integer := 480
	);
	port(
		center_x    : in signed(31 downto 0)   := x"FFFF8000"; -- -0.5 em Q16.16
		center_y    : in signed(31 downto 0)   := x"00000000"; --  0.0 em Q16.16
		zoom_factor : in unsigned(31 downto 0) := x"00000100"; -- Passo de ~0.0039 em Q16.16
		c_real      : out signed(31 downto 0);
		c_imag      : out signed(31 downto 0);
		pixel_x     : in std_logic_vector(9 downto 0);
      pixel_y     : in std_logic_vector(9 downto 0)
	);
end coordinate_generator;

architecture behavioral of coordinate_generator is
begin
	process(pixel_x, pixel_y, center_x, center_y, zoom_factor)
		variable dx : signed(31 downto 0);
		variable dy : signed(31 downto 0);
		variable prod_x : signed(63 downto 0);
		variable prod_y : signed(63 downto 0);
	begin
		-- Calcula a distância do pixel em relação ao centro da tela
		dx := to_signed(to_integer(unsigned(pixel_x)) - (SCREEN_WIDTH / 2), 32);
		dy := to_signed(to_integer(unsigned(pixel_y)) - (SCREEN_HEIGHT / 2), 32);
		
		-- Multiplica a distância pelo tamanho do passo (zoom_factor)
		/*prod_x := dx * signed(zoom_factor);
		prod_y := dy * signed(zoom_factor);*/
		prod_x := dx * signed'(x"00000100");
		prod_y := dy * signed'(x"00000100");
		
		-- Como zoom_factor é Q16.16, o produto vira Qxx.16. 
		-- Ajustamos a posição da vírgula trazendo 16 bits para a direita e truncando para 32 bits.
		c_real <= signed'(x"FFFF8000")/*center_x*/ + signed(prod_x(31 downto 0));
		c_imag <= signed'(x"00000000")/*center_y*/ + signed(prod_y(31 downto 0));
	end process;
end behavioral;