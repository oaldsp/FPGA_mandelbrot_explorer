--------------------
--
-- vga_640x480_test_de10.vhdl
-- Created: 7/16/18
-- By: johnsontimoj
-- For: EE3921
--
--------------------
--  Overview
--
-- Test for VGA_drvr in 640x480 mode
--
--
-- Instantiates the VGA_drvr module and drives RGB
--		640 x 480 at 25MHz
--  
--------------------------
--- Details 
--
--  uses switches as RGB input
--------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_640x480_test_de10 is
   port(
      MAX10_CLK1_50: 	in std_logic;	-- 50MHz
      SW: 			in std_logic_vector(9 downto 0);
      VGA_HS:		out std_logic;
		VGA_VS:		out std_logic;
		VGA_R: 		out std_logic_vector(3 downto 0);
		VGA_G: 		out std_logic_vector(3 downto 0);
		VGA_B: 		out std_logic_vector(3 downto 0)
    );
end;

architecture hardware of vga_640x480_test_de10 is
	-- intermediate signals
	signal	clk_25: 		std_logic;

	COMPONENT VGA_drvr
		GENERIC(
			-- Default VGA 640-by-480 display parameters
			H_back_porch: 	natural:=48; 	
			H_display: 		natural:=640; 
			H_front_porch: natural:=16; 	
			H_retrace: 		natural:=96; 	
			V_back_porch: 	natural:=33; 	
			V_display: 		natural:=480; 
			V_front_porch: natural:=10; 
			V_retrace: 		natural:=2;
			Color_bits:		natural:=4;
			H_sync_polarity: std_logic:= '0';	--  depends on standard (negative -> 0), (positive -> 1)
			V_sync_polarity: std_logic:= '0';	--  depends on standard (negative -> 0), (positive -> 1)
			-- calculated based on other generic parameters
			H_counter_size: natural:= 10;		--  depends on above generic values
			V_counter_size: natural:= 10		--  depends on above generic values
		);
		PORT(
			i_vid_clk 		:	IN STD_LOGIC;
			i_rstb 			:	IN STD_LOGIC;
			o_h_sync 		: 	OUT STD_LOGIC;
			o_v_sync 		: 	OUT STD_LOGIC;
			o_pixel_x		:	OUT STD_LOGIC_VECTOR(h_counter_size-1 DOWNTO 0);
			o_pixel_y		: 	OUT STD_LOGIC_VECTOR(v_counter_size-1 DOWNTO 0);
			o_vid_display	:	OUT STD_LOGIC;
			i_red_in			:	IN STD_LOGIC_VECTOR(color_bits-1 DOWNTO 0);
			i_green_in		:	IN STD_LOGIC_VECTOR(color_bits-1 DOWNTO 0);
			i_blue_in		:	IN STD_LOGIC_VECTOR(color_bits-1 DOWNTO 0);
			o_red_out		:	OUT STD_LOGIC_VECTOR(color_bits-1 DOWNTO 0);
			o_green_out		:	OUT STD_LOGIC_VECTOR(color_bits-1 DOWNTO 0);
			o_blue_out		:	OUT STD_LOGIC_VECTOR(color_bits-1 DOWNTO 0)
		);
	END COMPONENT;
	
	component pll_25MHz
		PORT
		(
			inclk0: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		);
	end component;

	
Begin
	------------------
	-- VGA_drvr
	------------------
	vga: VGA_drvr
		PORT MAP(
					i_vid_clk		=> clk_25,		
					i_rstb			=> SW(0)	,		
					o_h_sync			=> VGA_HS,		
					o_v_sync			=> VGA_VS,		
					--o_pixel_x			=> PIXEL_X,		
					--o_pixel_y			=> PIXEL_Y,		
					--o_vid_display	=> VID_DISPLAY,	
					i_red_in(0) 	=> SW(7), 
					i_red_in(1) 	=> SW(7), 
					i_red_in(2) 	=> SW(8), 
					i_red_in(3) 	=> SW(9),
					i_green_in(0) 	=> SW(4), 
					i_green_in(1) 	=> SW(4), 
					i_green_in(2) 	=> SW(5), 
					i_green_in(3) 	=> SW(6),
					i_blue_in(0) 	=> SW(1), 
					i_blue_in(1) 	=> SW(1), 
					i_blue_in(2) 	=> SW(2), 
					i_blue_in(3) 	=> SW(3),	
					o_red_out 		=> VGA_R,
					o_green_out 	=> VGA_G,
					o_blue_out 		=> VGA_B	
		);
						
	------------------
	--  Clock divider PLL
	------------------	
	pll : pll_25MHz 
		PORT MAP (	
					inclk0	=> MAX10_CLK1_50,
					c0	 		=> clk_25
		);	
	
end architecture;
	