library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity frame_buffer_controller is
port(
   clk         : in std_logic;
   reset       : in std_logic;
   write_x     : in unsigned(9 downto 0);
   write_y     : in unsigned(9 downto 0);
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
   
   -- CONTADORES INTERNOS AJUSTADOS PARA 160x120
   -- X precisa de 8 bits (0 a 159) e Y de 7 bits (0 a 119)
   signal internal_read_x : unsigned(7 downto 0) := (others => '0');
   signal internal_read_y : unsigned(6 downto 0) := (others => '0');
begin

   ------------------------------------------------
   -- READ PATH (Contador Sequencial de 160x120)
   ------------------------------------------------
   process(clk, reset)
   begin
      if reset = '1' then
         read_addr       <= (others => '0');
         internal_read_x <= (others => '0');
         internal_read_y <= (others => '0');
      elsif rising_edge(clk) then
         -- Endereço compactado para economizar espaço de RAM na FPGA
         -- Mantemos a saída em 20 bits preenchendo com zeros à esquerda
         read_addr <= "0000" & display_buffer & 
                      std_logic_vector(internal_read_y) & 
                      std_logic_vector(internal_read_x);

         -- Lógica do Contador de leitura (Loop de 160x120)
         if internal_read_x = 159 then
            internal_read_x <= (others => '0'); -- Fim da linha (X)
            
            if internal_read_y = 119 then
               internal_read_y <= (others => '0'); -- Fim do Frame (Y)
            else
               internal_read_y <= internal_read_y + 1;
            end if;
         else
            internal_read_x <= internal_read_x + 1;
         end if;
         
      end if;
   end process;

   ------------------------------------------------
   -- WRITE PATH (Mandelbrot adaptado para 160x120)
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
         
         -- Mapeia o endereço de escrita usando a mesma compactação da leitura
         write_addr <= "0000" & (display_buffer) & 
                       std_logic_vector(write_y(6 downto 0)) & 
                       std_logic_vector(write_x(7 downto 0));
                       
         if frame_ready = '1' then
            display_buffer <= not display_buffer;
         end if;
      end if;
   end process;

end architecture;