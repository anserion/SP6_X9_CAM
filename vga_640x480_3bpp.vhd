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

----------------------------------------------------------------------------------
-- Engineer: Andrey S. Ionisyan <anserion@gmail.com>
-- 
-- Description: VGA Controller 640x480_3bpp (1_Red,1_Green,1_Blue)
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity vga_640x480_3bpp is
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
end vga_640x480_3bpp;

architecture SP6_X9 of vga_640x480_3bpp is
   component counter_xy
   generic (
      n: natural range 1 to 10:=10;
      x_min: natural range 0 to 1023:=0;
      y_min: natural range 0 to 1023:=0;
      x_max: natural range 0 to 1023:=639;
      y_max: natural range 0 to 1023:=479
   );
   Port ( 
		clk   : in  STD_LOGIC;
      en    : in std_logic;
      reset : in std_logic;
      x     : out std_logic_vector (n-1 downto 0);
      y     : out std_logic_vector (n-1 downto 0)
	 );
   end component;
   
   constant hStartSync : natural := 16;
   constant hStartWin  : natural := hStartSync+52;
   constant hEndWin    : natural := hStartWin+640;
   constant hEndSync   : natural := hEndWin+48;
   constant hMaxCount  : natural := 800;
	
   constant vStartSync : natural := 10;
   constant vStartWin  : natural := vStartSync+10;
   constant vEndWin    : natural := vStartWin+480;
   constant vEndSync   : natural := vEndWin+20;
   constant vMaxCount  : natural := 525;
	
   signal hCounter   : std_logic_vector(9 downto 0) := (others => '0');
   signal vCounter   : std_logic_vector(9 downto 0) := (others => '0');
	signal reg_x      : std_logic_vector(9 downto 0) := (others => '0');
	signal reg_y      : std_logic_vector(9 downto 0) := (others => '0');
   signal reg_hSync  : std_logic := '1';
   signal reg_vSync  : std_logic := '1';
   signal hWin_de: std_logic := '1';
   signal vWin_de: std_logic := '1';
	signal reg_de     : std_logic := '1';
begin
   counter_xy_chip: counter_xy
   generic map(
      x_max => hMaxCount,
      y_max => vMaxCount
   )
   Port map( 
		clk   => clk,
      en    => en,
      reset => not(en),
      x     => hCounter,
      y     => vCounter
	 );

   counter_out_xy_chip: counter_xy
   Port map( 
		clk   => clk,
      en    => reg_de,
      reset => not(en),
      x     => reg_x,
      y     => reg_y
	 );
    
   hSync<=reg_hSync;
   vSync<=reg_vSync;
	x <= reg_x;
	y <= reg_y;
   dirty_x<=hCounter;
   dirty_y<=vCounter;
   de<=reg_de;
   reg_de<=en and not(hWin_de or vWin_de);
	
   process(clk)
   begin
		if rising_edge(clk) then
       if en='1' then
			if reg_de='1' then
					blue  <= pixel(2);
					green <= pixel(1);
					red   <= pixel(0);
			else
				red   <= '0';
				green <= '0';
				blue  <= '0';
			end if;

			if vCounter=vStartSync then reg_vSync <= '0';
         elsif vCounter=vEndSync then reg_vSync <= '1';
         end if;

         if reg_vSync='0' then
            if hCounter=hStartSync then reg_hSync <= '0';
            elsif hCounter=hEndSync then reg_hSync <= '1';
            end if;
         else reg_hSync <= '1';
         end if;

			if vCounter=vStartWin then vWin_de <= '0';
         elsif vCounter=vEndWin then vWin_de <= '1';
         end if;

         if vWin_de='0' then
            if hCounter=hStartWin then hWin_de <= '0';
            elsif hCounter=hEndWin then hWin_de <= '1';
            end if;
         else hWin_de <= '1';
         end if;
       else
         reg_hsync<='1'; reg_vsync<='1';
         hWin_de<='1'; vWin_de<='1';
       end if;
		end if;
	end process;
end SP6_X9;