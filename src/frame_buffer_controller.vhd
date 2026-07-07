library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity frame_buffer_controller is
port(
   clk   : in std_logic;
   reset : in std_logic;
	------------------------------------------------
   -- VGA coords
   ------------------------------------------------
   write_x : in unsigned(7 downto 0);
   write_y : in unsigned(6 downto 0);
	------------------------------------------------
   -- troca de buffer
   ------------------------------------------------
   frame_ready : in std_logic;
   ------------------------------------------------
   -- Escrita (Mandelbrot)
   ------------------------------------------------
   pixel_valid : in std_logic;
   pixel_data  : in std_logic_vector(8 downto 0);
   ------------------------------------------------
   -- RAM interface
   ------------------------------------------------
	ram_din  : out std_logic_vector(8 downto 0);
	write_addr : out unsigned(15 downto 0);
	ram_we   : out std_logic;
   read_addr  : out unsigned(15 downto 0)
);
end entity;

architecture frame_buffer_controller of frame_buffer_controller is
   signal display_buffer : std_logic := '0';
   signal swap_pending   : std_logic := '0';
   signal write_index : unsigned(14 downto 0) := (others=>'0');
   signal read_index  : unsigned(14 downto 0) := (others=>'0');
begin
	------------------------------------------------
   -- READ PATH (VGA)
   ------------------------------------------------
   process(clk, reset)
	begin
		if reset = '1' then
			read_index <= (others => '0');
		elsif rising_edge(clk) then
			if read_index = to_unsigned(32767, 15) then
					read_index <= (others => '0');
			else
					read_index <= read_index + 1;
			end if;
		end if;
	end process;
	read_addr <= display_buffer & read_index;

   process(clk, reset)
   begin
       if reset = '1' then
          write_index    <= (others=>'0');
          display_buffer <= '0';
          swap_pending   <= '0';
          ram_we         <= '0';
       elsif rising_edge(clk) then
			------------------------------------------------
			-- WRITE PATH (Mandelbrot)
			------------------------------------------------
          ram_we <= '0';
          if frame_ready = '1' then
				swap_pending <= '1';
			 end if;
          if pixel_valid = '1' then
            ram_we   <= '1';
            ram_din  <= pixel_data;
            write_addr <= display_buffer & write_index;
            write_index <= write_index + 1;
          end if;
			------------------------------------------------
			-- BUFFER SWAP
			------------------------------------------------
			 if swap_pending = '1' and write_x = 0 and write_y = 0 then
            display_buffer <= not display_buffer;
            swap_pending <= '0';
         end if;
       end if;
   end process;
end frame_buffer_controller;