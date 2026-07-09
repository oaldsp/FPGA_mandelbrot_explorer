-- Responsável por receber os comandos do usuário e atualizar posição e zoom.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_unit is
	port(
		clk         : in  std_logic;
		reset       : in  std_logic;
		mode_zoom   : in std_logic; -- 0=movimento, 1=zoom
		axis_select : in std_logic; -- 0=horizontal, 1=vertical
		btn_positive: in std_logic; -- direita/cima/zoom in (Ativo em Baixo '0')
		btn_negative: in std_logic; -- esquerda/baixo/zoom out (Ativo em Baixo '0')
		center_x    : out signed(31 downto 0);
		center_y    : out signed(31 downto 0);
		zoom_factor : out unsigned(31 downto 0);
		changed     : out std_logic  -- Pulso em '0' quando alguma coordenada mudar
	);
end control_unit;

architecture control_unit of control_unit is
	constant MOVE_STEP    : signed(31 downto 0) := to_signed(4096,32);
	constant INITIAL_X    : signed(31 downto 0) := x"FFFF8000";  -- -0.5 em Q16.16
	constant INITIAL_Y    : signed(31 downto 0) := x"00000000";   -- 0.0 em Q16.16
	constant INITIAL_ZOOM : unsigned(31 downto 0) := x"00000100"; -- Passo de ~0.0039 em Q16.16
	
	signal x_pos : signed(31 downto 0) := INITIAL_X; 
	signal y_pos : signed(31 downto 0) := INITIAL_Y;
	signal zoom  : unsigned(31 downto 0) := INITIAL_ZOOM;
	
	-- Registradores para detectar a borda dos botões
	signal btn_pos_reg : std_logic := '1';
	signal btn_neg_reg : std_logic := '1';
	
begin
   process(clk, reset)
   begin
		if reset = '0' then  -- Reset ativo em '0' (padrão dos botões KEY)
			x_pos <= INITIAL_X;
			y_pos <= INITIAL_Y;
			zoom  <= INITIAL_ZOOM;
			btn_pos_reg <= '1';
			btn_neg_reg <= '1';
			changed     <= '1';
		elsif rising_edge(clk) then
			-- Padrão: assume que nada mudou neste ciclo de clock
			changed <= '1';
			
			-- Atualiza os registradores de borda
			btn_pos_reg <= btn_positive;
			btn_neg_reg <= btn_negative;

			if mode_zoom = '1' then -- MODO ZOOM			
				-- Detecta quando o botão vai de SOLTO ('1') para PRESSIONADO ('0')
				if btn_positive = '0' and btn_pos_reg = '1' then
					zoom <= shift_right(zoom, 1); -- Zoom In
					changed <= '0';                -- Avisa que houve alteração
				end if;
				if btn_negative = '0' and btn_neg_reg = '1' then
					zoom <= shift_left(zoom, 1);  -- Zoom Out
					changed <= '0';                -- Avisa que houve alteração
				end if;
				
			else -- MODO MOVIMENTO
				if axis_select = '0' then -- Eixo Horizontal
					if btn_positive = '0' and btn_pos_reg = '1' then
						x_pos <= x_pos + MOVE_STEP; -- Direita
						changed <= '0';
					end if;
					if btn_negative = '0' and btn_neg_reg = '1' then
						x_pos <= x_pos - MOVE_STEP; -- Esquerda
						changed <= '0';
					end if;
				else -- Eixo Vertical
					if btn_positive = '0' and btn_pos_reg = '1' then
						y_pos <= y_pos + MOVE_STEP; -- Cima
						changed <= '0';
					end if;
					if btn_negative = '0' and btn_neg_reg = '1' then
						y_pos <= y_pos - MOVE_STEP; -- Baixo
						changed <= '0';
					end if;
				end if;
			end if;
		end if;
   end process;
   
   center_x    <= x_pos;
   center_y    <= y_pos;
   zoom_factor <= zoom;
   
end control_unit;