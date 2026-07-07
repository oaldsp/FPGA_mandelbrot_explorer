library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mandelbrot_scheduler is
    generic(
        MAX_ITERATIONS : integer := 255
    );
    port(
        -- Entradas do sistema
        clk                   : in  std_logic;
        reset                 : in  std_logic;
        pixel_valid_in        : in  std_logic;
		  c_real                : in  signed(31 downto 0);
        c_imag                : in  signed(31 downto 0);
        pixel_x               : in  unsigned(9 downto 0);
        pixel_y               : in  unsigned(9 downto 0);
        -- Saídas do sistema
		  pixel_x_out           : out unsigned(9 downto 0);
        pixel_y_out           : out unsigned(9 downto 0);
		  frame_ready           : out std_logic;
        pixel_valid           : out std_logic;
		  pixel_iteration_count : out unsigned(7 downto 0)
    );
end mandelbrot_scheduler;

architecture rtl of mandelbrot_scheduler is

    ---------------------------------------------------------------------------
    -- Componentes
    ---------------------------------------------------------------------------
    component mandelbrot_pixel_core is
        generic(
            MAX_ITERATIONS : integer := 255
        );
        port(
            clk             : in  std_logic;
            reset           : in  std_logic;
            start           : in  std_logic;
            c_real          : in  signed(31 downto 0);
            c_imag          : in  signed(31 downto 0);
            done            : out std_logic;
            iteration_count : out unsigned(7 downto 0)
        );
    end component;

    ---------------------------------------------------------------------------
    -- Constantes
    ---------------------------------------------------------------------------
    constant FRAME_PIXELS : integer := 65536;
    constant FIFO_DEPTH    : integer := 16; 

    ---------------------------------------------------------------------------
    -- Tipos e Sinais da FIFO
    ---------------------------------------------------------------------------
    type fifo_element is record
        x      : unsigned(9 downto 0);
        y      : unsigned(9 downto 0);
        c_real : signed(31 downto 0);
        c_imag : signed(31 downto 0);
    end record;

    type fifo_array is array (0 to FIFO_DEPTH-1) of fifo_element;
    signal fifo_mem       : fifo_array;
    signal fifo_wr_ptr    : integer range 0 to FIFO_DEPTH-1 := 0;
    signal fifo_rd_ptr    : integer range 0 to FIFO_DEPTH-1 := 0;
    signal fifo_count     : integer range 0 to FIFO_DEPTH := 0;
    signal fifo_empty     : std_logic;
    signal fifo_full      : std_logic;
    
    -- Sinais para interface de leitura da FIFO
    signal fifo_pop       : std_logic;
    signal fifo_out_data  : fifo_element;

    ---------------------------------------------------------------------------
    -- Tipos e Sinais dos Cores (Núcleos)
    ---------------------------------------------------------------------------
    type core_reg_t is record
        busy   : std_logic;
        x      : unsigned(9 downto 0);
        y      : unsigned(9 downto 0);
        c_real : signed(31 downto 0);
        c_imag : signed(31 downto 0);
    end record;

    type core_regs_array is array (0 to 3) of core_reg_t;
    signal core_regs : core_regs_array;

    -- Sinais de interface com as instâncias dos cores
    signal core_start : std_logic_vector(0 to 3);
    signal core_done  : std_logic_vector(0 to 3);
    type core_outputs_array is array (0 to 3) of unsigned(7 downto 0);
    signal core_iter  : core_outputs_array;

    ---------------------------------------------------------------------------
    -- Sinais de Controle de Frame
    ---------------------------------------------------------------------------
    signal pixel_counter : integer range 0 to FRAME_PIXELS := 0;

begin

    ---------------------------------------------------------------------------
    -- FIFO Circular Síncrona
    ---------------------------------------------------------------------------
    fifo_empty <= '1' when (fifo_count = 0) else '0';
    fifo_full  <= '1' when (fifo_count = FIFO_DEPTH) else '0';
    
    -- Saída combinacional do topo da FIFO para o scheduler
    fifo_out_data <= fifo_mem(fifo_rd_ptr);

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                fifo_wr_ptr <= 0;
                fifo_rd_ptr <= 0;
                fifo_count  <= 0;
            else
                -- Escrita na FIFO (Garante que não descarta se estiver cheia)
                if pixel_valid_in = '1' and fifo_full = '0' then
                    fifo_mem(fifo_wr_ptr).x      <= pixel_x;
                    fifo_mem(fifo_wr_ptr).y      <= pixel_y;
                    fifo_mem(fifo_wr_ptr).c_real <= c_real;
                    fifo_mem(fifo_wr_ptr).c_imag <= c_imag;
                    
                    if fifo_wr_ptr = FIFO_DEPTH-1 then
                        fifo_wr_ptr <= 0;
                    else
                        fifo_wr_ptr <= fifo_wr_ptr + 1;
                    end if;
                end if;

                -- Leitura da FIFO (Pop controlado pelo scheduler)
                if fifo_pop = '1' and fifo_empty = '0' then
                    if fifo_rd_ptr = FIFO_DEPTH-1 then
                        fifo_rd_ptr <= 0;
                    else
                        fifo_rd_ptr <= fifo_rd_ptr + 1;
                    end if;
                end if;

                -- Controle do contador de elementos internos da FIFO
                if (pixel_valid_in = '1' and fifo_full = '0') and not (fifo_pop = '1' and fifo_empty = '0') then
                    fifo_count <= fifo_count + 1;
                elsif not (pixel_valid_in = '1' and fifo_full = '0') and (fifo_pop = '1' and fifo_empty = '0') then
                    fifo_count <= fifo_count - 1;
                end if;
            end if;
        end if;
    end process;


    ---------------------------------------------------------------------------
    -- Instanciação dos Núcleos (Generate)
    ---------------------------------------------------------------------------
    gen_cores: for i in 0 to 3 generate
        core_inst : mandelbrot_pixel_core
            generic map(
                MAX_ITERATIONS => MAX_ITERATIONS
            )
            port map(
                clk             => clk,
                reset           => reset,
                start           => core_start(i),
                c_real          => core_regs(i).c_real,
                c_imag          => core_regs(i).c_imag,
                done            => core_done(i),
                iteration_count => core_iter(i)
            );
    end generate gen_cores;


    ---------------------------------------------------------------------------
    -- Escalonador (Scheduler)
    ---------------------------------------------------------------------------
    process(clk)
        variable core_assigned : boolean;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                fifo_pop   <= '0';
                core_start <= (others => '0');
                for i in 0 to 3 loop
                    core_regs(i).busy   <= '0';
                    core_regs(i).x      <= (others => '0');
                    core_regs(i).y      <= (others => '0');
                    core_regs(i).c_real <= (others => '0');
                    core_regs(i).c_imag <= (others => '0');
                end loop;
            else
                -- Defaults para os pulsos de um único ciclo de clock
                fifo_pop   <= '0';
                core_start <= (others => '0');
                
                -- Libera o núcleo assim que ele termina o processamento
                for i in 0 to 3 loop
                    if core_done(i) = '1' then
                        core_regs(i).busy <= '0';
                    end if;
                end loop;

                -- Lógica de distribuição: Busca o primeiro núcleo livre
                core_assigned := false;
                if fifo_empty = '0' then
                    for i in 0 to 3 loop
                        -- Condição: Core livre, não terminou neste mesmo ciclo e vaga ainda não preenchida
                        if core_regs(i).busy = '0' and core_done(i) = '0' and not core_assigned then
                            -- Despacha o pixel da FIFO para o Core correspondente
                            core_regs(i).busy   <= '1';
                            core_regs(i).x      <= fifo_out_data.x;
                            core_regs(i).y      <= fifo_out_data.y;
                            core_regs(i).c_real <= fifo_out_data.c_real;
                            core_regs(i).c_imag <= fifo_out_data.c_imag;
                            
                            core_start(i) <= '1'; -- Pulso de start
                            fifo_pop      <= '1'; -- Consome da FIFO
                            core_assigned := true; 
                        end if;
                    end loop;
                end if;
            end if;
        end if;
    end process;


    ---------------------------------------------------------------------------
    -- Coleta de Resultados (Arbitragem de Saída)
    ---------------------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pixel_valid           <= '0';
                pixel_x_out           <= (others => '0');
                pixel_y_out           <= (others => '0');
                pixel_iteration_count <= (others => '0');
            else
                -- Default
                pixel_valid <= '0';
                
                -- Varre os cores para colocar o dado pronto na saída global.
                for i in 0 to 3 loop
                    if core_done(i) = '1' then
                        pixel_valid           <= '1';
                        pixel_x_out           <= core_regs(i).x;
                        pixel_y_out           <= core_regs(i).y;
                        pixel_iteration_count <= core_iter(i);
                    end if;
                end loop;
            end if;
        end if;
    end process;


    ---------------------------------------------------------------------------
    -- Controle de Frame
    ---------------------------------------------------------------------------
    process(clk)
        variable finished_cores_count : integer range 0 to 4;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pixel_counter <= 0;
                frame_ready   <= '0';
            else
                frame_ready <= '0'; -- Pulso padrão de um ciclo
                
                -- Conta quantos núcleos terminaram simultaneamente neste ciclo de clock
                finished_cores_count := 0;
                for i in 0 to 3 loop
                    if core_done(i) = '1' then
                        finished_cores_count := finished_cores_count + 1;
                    end if;
                end loop;

                -- Atualiza o contador geral de pixels calculados do Frame atual
                if finished_cores_count > 0 then
                    if (pixel_counter + finished_cores_count) >= FRAME_PIXELS then
                        pixel_counter <= (pixel_counter + finished_cores_count) - FRAME_PIXELS;
                        frame_ready   <= '1';
                    else
                        pixel_counter <= pixel_counter + finished_cores_count;
                    end if;
                end if;
            end if;
        end if;
    end process;

end rtl;