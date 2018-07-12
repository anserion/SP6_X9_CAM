------------------------------------------------------------------
--Copyright 2018 Andrey S. Ionisyan (anserion@gmail.com)
--Licensed under the Apache License, Version 2.0 (the "License");
--you may not use this file except in compliance with the License.
--You may obtain a copy of the License at
--    http://www.apache.org/licenses/LICENSE-2.0
--Unless required by applicable law or agreed to in writing, software
--distributed under the License is distributed on an "AS IS" BASIS,
--WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--See the License for the specific language governing permissions and
--limitations under the License.
------------------------------------------------------------------

------------------------------------------------------------------------------
-- Engineer: Andrey S. Ionisyan <anserion@gmail.com>
-- Description:
-- Top level for the ov7670 cam to VGA 3bpp video stream (X-SP6-X9 board)
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SP6_X9_CAM_top is
   port (
      clk50_ucf: in STD_LOGIC;

		OV7670_SIOC  : out   STD_LOGIC;
		OV7670_SIOD  : inout STD_LOGIC;
		OV7670_RESET : out   STD_LOGIC;
		OV7670_PWDN  : out   STD_LOGIC;
		OV7670_VSYNC : in    STD_LOGIC;
		OV7670_HREF  : in    STD_LOGIC;
		OV7670_PCLK  : in    STD_LOGIC;
		OV7670_XCLK  : out   STD_LOGIC;
		OV7670_D     : in    STD_LOGIC_VECTOR(7 downto 0);

      lcd_bus : out STD_LOGIC_VECTOR(7 downto 0);
      lcd_e   : out STD_LOGIC;
      lcd_rw  : out STD_LOGIC;
      lcd_rs  : out STD_LOGIC;
      
		vga_red      : out STD_LOGIC;
		vga_green    : out STD_LOGIC;
		vga_blue     : out STD_LOGIC;
		vga_hsync    : out STD_LOGIC;
		vga_vsync    : out STD_LOGIC
   );
end SP6_X9_CAM_top;

architecture SP6_X9 of SP6_X9_CAM_top is
   COMPONENT framebuffer_640x480_1bpp
   PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(18 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
   );
   END COMPONENT;

   COMPONENT framebuffer_128x64_1bpp
   PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(8 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
   );
   END COMPONENT;
   
   component clocking_core
   port (
      CLK_50_in : in  std_logic;
      CLK_50    : out std_logic;
      CLK_25    : out std_logic;
      CLK_12_5  : out std_logic;
      CLK_6_25  : out std_logic      
      );
   end component;

   component freq_div_module
    Port ( 
		clk   : in  STD_LOGIC;
      en    : in  STD_LOGIC;
      value : in  STD_LOGIC_VECTOR(31 downto 0);
      result: out STD_LOGIC
	 );
   end component;

   component ov7670_capture is
    Port (
      en    : in std_logic;
      clk   : in std_logic;
      vsync : in std_logic;
		href  : in std_logic;
		din   : in std_logic_vector(7 downto 0);
      cam_x : out std_logic_vector(9 downto 0);
      cam_y : out std_logic_vector(9 downto 0);
      pixel : out std_logic_vector(15 downto 0);
      ready : out std_logic
		);
   end component;

   COMPONENT vga_640x480_3bpp
    Port (
      en    : in std_logic;
		clk   : in  STD_LOGIC;
		red   : out STD_LOGIC;
		green : out STD_LOGIC;
		blue  : out STD_LOGIC;
		hsync : out STD_LOGIC;
		vsync : out STD_LOGIC;
      de    : out STD_LOGIC;
		x     : out STD_LOGIC_VECTOR(9 downto 0);
		y     : out STD_LOGIC_VECTOR(9 downto 0);
      dirty_x : out STD_LOGIC_VECTOR(9 downto 0);
      dirty_y : out STD_LOGIC_VECTOR(9 downto 0);
      pixel :  in STD_LOGIC_VECTOR(2 downto 0)
	 );
   END COMPONENT;

   component lcd_128x64_1bpp is
    Port (
      en     : in std_logic;
      clk_10Khz: in  STD_LOGIC;
      lcd_bus: out STD_LOGIC_VECTOR(7 downto 0);
      lcd_e  : out STD_LOGIC;
      lcd_rs : out STD_LOGIC;
      lcd_rw : out STD_LOGIC;
      x      : out STD_LOGIC_VECTOR(2 downto 0);
      y      : out STD_LOGIC_VECTOR(5 downto 0);
      pixels_pack: in STD_LOGIC_VECTOR(15 downto 0)
    );
   end component;

   signal vga_clk   : std_logic := '0';
   signal vga_en    : std_logic := '1';
   signal vga_de    : std_logic := '0';
	signal vga_reg_hsync: STD_LOGIC :='1';
	signal vga_reg_vsync: STD_LOGIC :='1';
   signal vga_x     : std_logic_vector(9 downto 0) := (others => '0');
   signal vga_y     : std_logic_vector(9 downto 0) := (others => '0');
   signal vga_addr  : std_logic_vector(19 downto 0) := (others => '0');
   signal vga_dirty_x: std_logic_vector(9 downto 0) := (others => '0');
   signal vga_dirty_y: std_logic_vector(9 downto 0) := (others => '0');	
   signal vga_pixel : std_logic_vector(2 downto 0) := (others => '0');

   signal cam_clk, cam_clk_div2 : std_logic := '0';
   signal cam_en       : std_logic := '1';
   signal cam_pixel_ready: std_logic := '0';
   signal cam_y      : std_logic_vector(9 downto 0):=(others=>'0');
   signal cam_x      : std_logic_vector(9 downto 0):=(others=>'0');
   signal cam_addr  : std_logic_vector(19 downto 0) := (others => '0');
   signal cam_pixel  : std_logic_vector(15 downto 0):=(others=>'0');
   
   signal fb_VGA_pixel  : std_logic_vector(2 downto 0):=(others=>'0');
   signal fb_VGA_pixel_reg: std_logic_vector(0 downto 0):=(others=>'0');
   signal fb_lcd_pixels_reg: std_logic_vector(15 downto 0):=(others=>'0');

   signal lcd_clk   : std_logic := '0';
   signal lcd_en    : std_logic := '1';
   signal lcd_x     : std_logic_vector(2 downto 0) := (others => '0');
   signal lcd_y     : std_logic_vector(5 downto 0) := (others => '0');
   signal lcd_pixels_pack : std_logic_vector(15 downto 0);
   signal lcd_pixel : std_logic:='0';

   signal tmp_x     : std_logic_vector(6 downto 0) := (others => '0');
   signal tmp_y     : std_logic_vector(5 downto 0) := (others => '0');
      
   signal clk50,clk25,clk12_5,clk6_25,clk_10Khz : std_logic:='0';
begin
   clocking_chip : clocking_core PORT MAP (CLK50_ucf,clk50,clk25,clk12_5,clk6_25);
-------------------------------------------------------------

   cam_en<='1';
   cam_clk<=clk12_5;
   cam_clk_div2<=clk6_25;
   --minimal OV7670 grayscale mode
   OV7670_PWDN  <= '1';--board bug (must be '0'); --0 - power on
   OV7670_RESET <= '0';--board bug (must be '1'); --0 -activate reset
   OV7670_XCLK  <= cam_clk;
   ov7670_siod  <= 'Z';
   ov7670_sioc  <= '0';
   
   capture: ov7670_capture PORT MAP(
      en    => cam_en,
      clk   => OV7670_PCLK,
      vsync => OV7670_VSYNC,
      href  => OV7670_HREF,
      din   => OV7670_D,
      cam_x => cam_x,
      cam_y => cam_y,
      pixel => cam_pixel,
      ready => cam_pixel_ready
      );
   cam_addr<=conv_std_logic_vector(640,10)*cam_y+cam_x;
-----------------------------------------------------------------
  
   vga_clk<=clk25;
   vga_en<='1';
   vga_hsync<=vga_reg_hsync;
   vga_vsync<=vga_reg_vsync;
   
	vga_640x480x3bpp_chip: vga_640x480_3bpp PORT MAP(
      en    => vga_en,
		clk   => vga_clk,
		red   => vga_red,
		green => vga_green,
		blue  => vga_blue,
		hsync => vga_reg_hsync,
		vsync => vga_reg_vsync,
      de    => vga_de,
		x     => vga_x,
		y     => vga_y,
      dirty_x=>vga_dirty_x,
      dirty_y=>vga_dirty_y,
		pixel => vga_pixel
      );

   vga_addr<=conv_std_logic_vector(640,10)*vga_y+vga_x;
   
   vga_pixel<=(others=>'1') when
      (vga_y=10)or(vga_y=240)or(vga_y=470)or
      (vga_x=10)or(vga_x=320)or(vga_x=630)
   else fb_VGA_pixel;
   
   fb_VGA_pixel(2)<=fb_VGA_pixel_reg(0);
   fb_VGA_pixel(1)<=fb_VGA_pixel_reg(0);
   fb_VGA_pixel(0)<=fb_VGA_pixel_reg(0);
   
   framebuffer_640x480_chip : framebuffer_640x480_1bpp
   PORT MAP (
    clka  => cam_clk_div2,
    wea   => "1",
    addra => cam_addr(18 downto 0),
    dina  => (0=>cam_pixel(7)),
    clkb  => vga_clk,
    addrb => vga_addr(18 downto 0),
    doutb => fb_VGA_pixel_reg
   );
--------------------------------------------------------   

   --in real 50 MHz div 2000 is 25000 Hz (overclocking!!!! --> 8 FPS)
   clk_10kHz_chip: freq_div_module port map(
      clk50,'1',conv_std_logic_vector(1000,32),clk_10kHz
   );
   
   lcd_en<='1';
   lcd_clk<=clk_10Khz;

   lcd_128x64_1bpp_chip: lcd_128x64_1bpp port map (
      en      => lcd_en,
      clk_10Khz=> lcd_clk,
      lcd_bus => lcd_bus,
      lcd_e   => lcd_e,
      lcd_rs  => lcd_rs,
      lcd_rw  => lcd_rw,
      x       => lcd_x,
      y       => lcd_y,
      pixels_pack   => lcd_pixels_pack
    );
    
-- debug XY-generator
--   process (cam_clk_div2)
--   begin
--      if rising_edge(cam_clk_div2) then
--         tmp_x<=tmp_x+1;
--         if tmp_x=0 then tmp_y<=tmp_y+1; end if;
--      end if;
--   end process;
   
   tmp_y<=cam_y(8 downto 3);
   tmp_x<=cam_x(9 downto 3);
   
   -- decoration frame around camera image
   lcd_pixel<='1' when
         ((tmp_y=0)or(tmp_y=59)or(tmp_x=0)or(tmp_x=79))
         and (tmp_x<80) and (tmp_y<60)
      else cam_pixel(7);
      
   framebuffer_128x64_chip : framebuffer_128x64_1bpp
   PORT MAP (
    clka  => cam_clk_div2,
    wea   => "1",
    addra => tmp_y & tmp_x,
    dina  => (0=>lcd_pixel),
    clkb  => lcd_clk,
    addrb => lcd_y & lcd_x,
    doutb => lcd_pixels_pack
   );
      
end SP6_X9;
