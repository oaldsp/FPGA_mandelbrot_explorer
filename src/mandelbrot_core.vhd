-- Responsável por calcular o Mandelbrot de uma linha.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_core is
    generic(
        SCREEN_WIDTH : integer := 640
    );

    port(
        clk   : in std_logic;
        reset : in std_logic;

        start : in std_logic;

        line_number : in unsigned(9 downto 0);

        done : out std_logic;

        pixel_x : out unsigned(9 downto 0);

        pixel_iteration : out unsigned(7 downto 0);

        pixel_valid : out std_logic
    );

end mandelbrot_core;

architecture rtl of mandelbrot_core is

    signal current_pixel : unsigned(9 downto 0);

    signal pixel_start : std_logic;
    signal pixel_done  : std_logic;

    signal c_real : signed(31 downto 0);
    signal c_imag : signed(31 downto 0);

    signal iteration_count : unsigned(7 downto 0);

    type state_t is (
        IDLE,
        START_PIXEL,
        WAIT_PIXEL,
        NEXT_PIXEL,
        FINISHED
    );

    signal state : state_t := IDLE;

begin

    ------------------------------------------------------------------
    -- Instância do núcleo de cálculo de pixel
    ------------------------------------------------------------------

    pixel_engine : entity work.mandelbrot_pixel_core
    port map(
        clk => clk,
        reset => reset,
        start => pixel_start,

        c_real => c_real,
        c_imag => c_imag,

        done => pixel_done,

        iteration_count => iteration_count
    );

    ------------------------------------------------------------------
    -- Máquina de estados
    ------------------------------------------------------------------

    process(clk, reset)
    begin

        if reset='1' then

            state <= IDLE;

            current_pixel <= (others=>'0');

            pixel_start <= '0';

            pixel_valid <= '0';

            done <= '0';

        elsif rising_edge(clk) then

            pixel_start <= '0';

            pixel_valid <= '0';

            case state is

                ------------------------------------------------------

                when IDLE =>

                    done <= '0';

                    if start='1' then

                        current_pixel <= (others=>'0');

                        state <= START_PIXEL;

                    end if;

                ------------------------------------------------------

                when START_PIXEL =>

                    pixel_start <= '1';

                    state <= WAIT_PIXEL;

                ------------------------------------------------------

                when WAIT_PIXEL =>

                    if pixel_done='1' then

                        pixel_valid <= '1';

                        pixel_iteration <= iteration_count;

                        pixel_x <= current_pixel;

                        state <= NEXT_PIXEL;

                    end if;

                ------------------------------------------------------

                when NEXT_PIXEL =>

                    if to_integer(current_pixel) =
                       SCREEN_WIDTH-1 then

                        state <= FINISHED;

                    else

                        current_pixel <= current_pixel + 1;

                        state <= START_PIXEL;

                    end if;

                ------------------------------------------------------

                when FINISHED =>

                    done <= '1';

                    state <= IDLE;

            end case;

        end if;

    end process;

end rtl;