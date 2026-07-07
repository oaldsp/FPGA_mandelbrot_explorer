library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity frame_buffer_controller is
port(
   clk         : in std_logic;
   reset       : in std_logic;
   write_x     : in unsigned(9 downto 0);
   write_y     : in unsigned(9 downto 0);
   -- Os sinais read_x e read_y externos não são mais necessários para o endereço de leitura
   frame_ready : in std_logic;
   pixel_valid : in std_logic;
   pixel_data  : in std_logic_vector(8 downto 0); 
   
   ram_din     : out std_logic_vector(8 downto 0);
   write_addr  : out std_logic_vector(19 downto 0);
   ram_we      : out std_logic;
   read_addr   : out std_logic_vector(19 downto 0)
);
end entity;

architecture frame_buffer_controller of frame_buffer_controller is
   signal display_buffer : std_logic := '0';
   
   -- CONTADORES INTERNOS PARA O LOOP DE LEITURA
   signal internal_read_x : unsigned(9 downto 0) := (others => '0');
   signal internal_read_y : unsigned(9 downto 0) := (others => '0');
   
begin

   ------------------------------------------------
   -- READ PATH (Contador Sequencial / Loop Automático)
   ------------------------------------------------
   process(clk, reset)
   begin
      if reset = '1' then
         read_addr       <= (others => '0');
         internal_read_x <= (others => '0');
         internal_read_y <= (others => '0');
         
      elsif rising_edge(clk) then
         -- 1. Atualiza o endereço com base no contador interno atual
         read_addr <= display_buffer & 
                      std_logic_vector(internal_read_y(8 downto 0)) & 
                      std_logic_vector(internal_read_x(9 downto 0));

         -- 2. Lógica do Contador (Loop de 640x480)
         if internal_read_x = 639 then
            internal_read_x <= (others => '0'); -- Reseta X (Fim da linha)
            
            if internal_read_y = 479 then
               internal_read_y <= (others => '0'); -- Reseta Y (Fim do Frame / Fecha o Loop)
            else
               internal_read_y <= internal_read_y + 1; -- Próxima linha
            end if;
         else
            internal_read_x <= internal_read_x + 1; -- Próximo pixel
         end if;
         
      end if;
   end process;

   ------------------------------------------------
   -- WRITE PATH (Mandelbrot) - Mantido igual
   ------------------------------------------------
   process(clk, reset)
   begin
      if reset = '1' then
         write_addr     <= (others => '0');
         ram_din        <= (others => '0');
         display_buffer <= '0';
         ram_we         <= '0';
      elsif rising_edge(clk) then
         ram_we  <= pixel_valid;
         ram_din <= pixel_data;
         
         write_addr <= (not display_buffer) & 
                       std_logic_vector(write_y(8 downto 0)) & 
                       std_logic_vector(write_x(9 downto 0));
                       
         if frame_ready = '1' then
            display_buffer <= not display_buffer;
         end if;
      end if;
   end process;

end architecture;