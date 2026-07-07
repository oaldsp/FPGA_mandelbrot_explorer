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
		center_x : in signed(31 downto 0);
		center_y : in signed(31 downto 0);
		zoom_factor : in unsigned(31 downto 0);
		c_real : out signed(31 downto 0);
		c_imag : out signed(31 downto 0);
		pixel_x : in unsigned(7 downto 0);
		pixel_y : in unsigned(6 downto 0)
	);
end coordinate_generator;

architecture coordinate_generator of coordinate_generator is
begin
	process(pixel_x,pixel_y,center_x,center_y,zoom_factor)
		variable dx : signed(31 downto 0);
		variable dy : signed(31 downto 0);
	begin
		-- Passe de coordenadas somente positivas para positivas e negativas
		dx := to_signed(to_integer(pixel_x) - SCREEN_WIDTH/2,32);
		dy := to_signed(to_integer(pixel_y) - SCREEN_HEIGHT/2,32);
		-- Transforma para números imaginários
		c_real <= center_x + resize(shift_right(dx * signed(zoom_factor),16),32);
		c_imag <= center_y + resize(shift_right(dy * signed(zoom_factor),16),32);
	end process;
end coordinate_generator;