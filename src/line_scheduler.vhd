-- Distribui linhas dinamicamente entre os núcleos Mandelbrot.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity line_scheduler is
	generic(
		IMAGE_HEIGHT : integer := 480
   );
	port(
		clk : in std_logic;
		reset : in std_logic;
		request_line : in std_logic;
		assigned_line : out unsigned(9 downto 0);
		frame_done : out std_logic
	);
end line_scheduler;

architecture line_scheduler of line_scheduler is
	signal next_line : unsigned(9 downto 0) := (others=>'0');
begin
   process(clk, reset)
   begin
		if reset='1' then
			next_line <= (others=>'0');
      elsif rising_edge(clk) then
			if (request_line='1') and (to_integer(next_line) < IMAGE_HEIGHT) then
			next_line <= next_line + 1;
			end if;
		end if;
	end process;
	
   assigned_line <= next_line;
   frame_done <= '1' when to_integer(next_line) >= IMAGE_HEIGHT else '0';
end line_scheduler;