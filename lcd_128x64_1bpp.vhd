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
-- Description: LCD12864 Controller 128x64_1bpp
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity lcd_128x64_1bpp is
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
end lcd_128x64_1bpp;

architecture SP6_X9 of lcd_128x64_1bpp is
   signal x_reg:std_logic_vector(3 downto 0) := (others=>'0');
   signal y_reg:std_logic_vector(4 downto 0) := (others=>'0');
   signal fsm: natural range 0 to 15 := 0;
   signal fsm_sub:natural range 0 to 3 := 0;
   signal cnt: std_logic_vector(7 downto 0) := (others=>'0');

begin
	x <= x_reg(2 downto 0);
	y <= x_reg(3) & y_reg;
   
   process(clk_10kHz)
   begin
		if rising_edge(clk_10kHz) then
      
      -- Init section
      case fsm is
      when 0=>
         -- specify 8-bit parallel interface and basic Instructions set
         case fsm_sub is
         when 0=>
            lcd_e<='0'; lcd_rs<='0'; lcd_rw<='0';
            lcd_bus<="00110000";
            fsm_sub<=1;
         when 1=> lcd_e<='1'; fsm_sub<=2;
         when 2=> lcd_e<='0'; fsm_sub<=0; fsm<=6;
         when others=>null;
         end case;
      when 1=>
         -- init delay more than 40 microseconds
         -- 200 ticks at 10kHz clk is enought :)
         case fsm_sub is
         when 0=> cnt<=(others=>'0'); fsm_sub<=1;
         when 1=>
            if cnt=200 then
               fsm_sub<=0; fsm<=2;
            else
               cnt<=cnt+1;
            end if;
         when others=>null;
         end case;
      when 2=>
         -- specify 8-bit parallel interface and basic Instructions set
         case fsm_sub is
         when 0=>
            lcd_e<='0'; lcd_rs<='0'; lcd_rw<='0';
            lcd_bus<="00110000";
            fsm_sub<=1;
         when 1=> lcd_e<='1'; fsm_sub<=2;
         when 2=> lcd_e<='0'; fsm_sub<=0; fsm<=3;
         when others=>null;
         end case;
      when 3=>
         -- Display ON, Cursor OFF, Blink OFF
         case fsm_sub is
         when 0=>
            lcd_e<='0'; lcd_rs<='0'; lcd_rw<='0';
            lcd_bus<="00001100";
            fsm_sub<=1;
         when 1=> lcd_e<='1'; fsm_sub<=2;
         when 2=> lcd_e<='0'; fsm_sub<=0; fsm<=4;
         when others=>null;
         end case;
      when 4=>
         -- Display Clear
         case fsm_sub is
         when 0=>
            lcd_e<='0'; lcd_rs<='0'; lcd_rw<='0';
            lcd_bus<="00000001";
            fsm_sub<=1;
         when 1=> lcd_e<='1'; fsm_sub<=2;
         when 2=> lcd_e<='0'; fsm_sub<=0; fsm<=5;
         when others=>null;
         end case;
      when 5=>
         -- ENTRY MODE (AC increase, don't shift the display)
         case fsm_sub is
         when 0=>
            lcd_e<='0'; lcd_rs<='0'; lcd_rw<='0';
            lcd_bus<="00000110";
            fsm_sub<=1;
         when 1=> lcd_e<='1'; fsm_sub<=2;
         when 2=> lcd_e<='0'; fsm_sub<=0; fsm<=6;
         when others=>null;
         end case;
      when 6=>
         -- Select extended Instructions set
         case fsm_sub is
         when 0=>
            lcd_e<='0'; lcd_rs<='0'; lcd_rw<='0';
            lcd_bus<="00110100";
            fsm_sub<=1;
         when 1=> lcd_e<='1'; fsm_sub<=2;
         when 2=> lcd_e<='0'; fsm_sub<=0; fsm<=7;
         when others=>null;
         end case;
      when 7=>
         -- Graphics display ON
         case fsm_sub is
         when 0=>
            lcd_e<='0'; lcd_rs<='0'; lcd_rw<='0';
            lcd_bus<="00110110";
            fsm_sub<=1;
         when 1=> lcd_e<='1'; fsm_sub<=2;
         when 2=> lcd_e<='0'; fsm_sub<=0; fsm<=10;
         when others=>null;
         end case;

      -- LCD left top corner init
      when 10=>
         x_reg<=(others=>'0');
         y_reg<=(others=>'0');
         fsm<=11;
         
      -- set position to start of new line (0,y_reg)
      when 11=>
         -- set vertical address (0-31 union of top and bottom lines)
         case fsm_sub is
         when 0=>
            lcd_e<='0'; lcd_rs<='0'; lcd_rw<='0';
            lcd_bus<="100"&y_reg;
            fsm_sub<=1;
         when 1=> lcd_e<='1'; fsm_sub<=2;
         when 2=> lcd_e<='0'; fsm_sub<=0; fsm<=12;
         when others=>null;
         end case;
      when 12=>
         -- set horizontal address (1 step is 16 pixels)
         case fsm_sub is
         when 0=>
            lcd_e<='0'; lcd_rs<='0'; lcd_rw<='0';
            --lcd_bus<="1000" & x_reg;
            lcd_bus<="10000000";
            fsm_sub<=1;
         when 1=> lcd_e<='1'; fsm_sub<=2;
         when 2=> lcd_e<='0'; fsm_sub<=0; fsm<=13;
         when others=>null;
         end case;

      -- send 256 pixels by 16-bit blocks (2 bytes) to line union y_reg
      when 13=>
         case fsm_sub is
         when 0=>
            lcd_e<='0'; lcd_rs<='1'; lcd_rw<='0';
            lcd_bus<=--pixels_pack(15 downto 8);
               pixels_pack(0)&pixels_pack(1)&pixels_pack(2)&pixels_pack(3)&
               pixels_pack(4)&pixels_pack(5)&pixels_pack(6)&pixels_pack(7);
            fsm_sub<=1;
         when 1=> lcd_e<='1'; fsm_sub<=2;
         when 2=> lcd_e<='0'; fsm_sub<=0; fsm<=14;
         when others=>null;
         end case;
      when 14=> 
         case fsm_sub is
         when 0=>
            lcd_e<='0'; lcd_rs<='1'; lcd_rw<='0';
            lcd_bus<=--pixels_pack(7 downto 0);
               pixels_pack( 8)&pixels_pack( 9)&pixels_pack(10)&pixels_pack(11)&
               pixels_pack(12)&pixels_pack(13)&pixels_pack(14)&pixels_pack(15);
            fsm_sub<=1;
         when 1=> lcd_e<='1'; fsm_sub<=2; x_reg<=x_reg+1;
         when 2=> lcd_e<='0'; fsm_sub<=0; 
            if x_reg=0 then y_reg<=y_reg+1; fsm<=11; else fsm<=13; end if;         
         when others=>null; 
         end case;

      when others=>null;
      end case;
		end if;
	end process;
end SP6_X9;
