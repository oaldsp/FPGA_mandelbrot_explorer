-- Responsável por receber os comandos do usuário e atualizar posição e zoom.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
	port(
		clk         : in  std_logic;
		reset       : in  std_logic;
		mode_zoom      : in std_logic; -- 0=movimento, 1=zoom
		axis_select    : in std_logic; -- 0=horizontal, 1=vertical
		btn_positive   : in std_logic; -- direita/cima/zoom in
		btn_negative   : in std_logic; -- esquerda/baixo/zoom out
		center_x    : out signed(31 downto 0);
		center_y    : out signed(31 downto 0);
		zoom_factor : out unsigned(31 downto 0)
	);
end control_unit;

architecture control_unit of control_unit is
	-- Determina quanto se move cada vez que um botão é pressionado.
	constant MOVE_STEP    : signed(31 downto 0) := to_signed(4096,32);
	-- -0.5 em Q16.16
	constant INITIAL_X    : signed(31 downto 0) := to_signed(-(2**15), 32); -- Isso dá -0.5
	constant INITIAL_Y    : signed(31 downto 0) := to_signed(0, 32);        -- Isso dá 0.0
	constant INITIAL_ZOOM : unsigned(31 downto 0) := to_unsigned(2**16, 32);-- Isso dá 1.0
	
	signal x_pos : signed(31 downto 0) := INITIAL_X; 
	signal y_pos : signed(31 downto 0) := INITIAL_Y;
	signal zoom  : unsigned(31 downto 0) := INITIAL_ZOOM;
	
begin
   process(clk, reset)
   begin
		if reset = '1' then
			x_pos <= INITIAL_X;
			y_pos <= INITIAL_Y;
			zoom  <= INITIAL_ZOOM;
		elsif rising_edge(clk) then
			if mode_zoom = '1' then -- Modo Zoom			
				if btn_positive = '1' then
					zoom <= shift_right(zoom, 1); -- Zoom In
				end if;
				if btn_negative = '1' then
					zoom <= shift_left(zoom, 1); -- Zoom Out
				end if;
			else -- Modo Movimento
				if axis_select = '0' then -- Horizontal
					if btn_positive = '1' then
						x_pos <= x_pos + MOVE_STEP; -- Direita
					end if;
					if btn_negative = '1' then
						x_pos <= x_pos - MOVE_STEP; -- Esquerda
					end if;
				else -- Vertical
					if btn_positive = '1' then
						y_pos <= y_pos + MOVE_STEP; -- Cima
					end if;
					if btn_negative = '1' then
						y_pos <= y_pos - MOVE_STEP; -- Baixo
					end if;
				end if;
			end if;
		end if;
    end process;
	 
    center_x <= x_pos;
    center_y <= y_pos;
    zoom_factor <= zoom;
end control_unit;