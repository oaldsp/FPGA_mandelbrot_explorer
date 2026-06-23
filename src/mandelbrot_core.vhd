-- Núcleo responsável por calcular uma linha.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_core is
	generic(
		MAX_ITERATIONS : integer := 255
	);
   port(
		clk : in std_logic;
		reset : in std_logic;
		start : in std_logic;
		c_real : in signed(31 downto 0);
		c_imag : in signed(31 downto 0);
		done : out std_logic;
		iteration_count : out unsigned(7 downto 0)
	);
end mandelbrot_core;

architecture mandelbrot_core of mandelbrot_core is
	signal zr : signed(31 downto 0);
	signal zi : signed(31 downto 0);
	signal iter : unsigned(7 downto 0);
	signal running : std_logic := '0';
begin
   process(clk, reset)
		variable zr2 : signed(63 downto 0);
		variable zi2 : signed(63 downto 0);
		variable zri : signed(63 downto 0);
		variable magnitude : signed(63 downto 0);
   begin
      if reset='1' then
			zr <= (others=>'0');
         zi <= (others=>'0');
         iter <= (others=>'0');
         running <= '0';
			done <= '0';
      elsif rising_edge(clk) then
         if start='1' then
				zr <= (others=>'0');
				zi <= (others=>'0');
				iter <= (others=>'0');
				running <= '1';
				done <= '0';
         elsif running='1' then
				-- |z|^2 = zr^2 ​+ zi^2​				
				zr2 := zr * zr; -- 64 bits
				zi2 := zi * zi; -- 64 bits
				magnitude := zr2 + zi2;
				----------------------
				zri := zr * zi; -- 64 bits			
				-- ∣z∣^2 > 4
				-- Valida de já passou do valor
				if magnitude > to_signed(4*(2**32),64) then -- 4 com 32 bits depois da virgula
               running <= '0';
					done <= '1';
				-- Valida de já passou do numero de iterações
				elsif to_integer(iter) >= MAX_ITERATIONS then
               running <= '0';
               done <= '1';
				-- Se não cálcula o próximo valor
            else
					-- zn+1 ​= zn^2 ​+ c
					-- zn+1​ = (zr​ + zi*​i)^2 + (cr​ + ci*​i)
					-- zr ​= zr^2​ − zi^2 ​+ cr
					-- zi ​= 2*zr*​zi ​+ ci​
               zr <= resize(shift_right(zr2 - zi2,16), 32) + c_real;
               zi <= resize(shift_right(2*zri,16), 32) + c_imag;
               iter <= iter + 1;
				end if;
			end if;
		end if;
	end process;
	
	iteration_count <= iter;
end mandelbrot_core;