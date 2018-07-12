------------------------------------------------------------------
--Copyright 2017 Andrey S. Ionisyan (anserion@gmail.com)
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
-- Description: Captures pixels from OV7670 640x480 camera 16bpp out
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ov7670_capture is
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
end ov7670_capture;

architecture SP6_X9 of ov7670_capture is
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
   
   signal byte1    : std_logic_vector(7 downto 0):= (others => '0');
   signal byte2    : std_logic_vector(7 downto 0):= (others => '0');
   signal ready_reg: std_logic:= '0';
   signal x,y      : std_logic_vector(9 downto 0):=(others=>'0');
   signal FSM  : natural range 0 to 1 :=0;
   
begin
   ready<=ready_reg;
   counter_xy_chip: counter_xy Port map(clk,ready_reg,'0',x,y);
   process(clk)
   begin
      if rising_edge(clk) then
         if vsync='1' or href='0' then 
           FSM <= 0;
           ready_reg<='0';
         else
            case FSM is
               when 0 => 
                  ready_reg<='0';
                  byte1<=din;
               when 1 =>
                  ready_reg<='1';
                  byte2<=din;
                  cam_x<=x;
                  cam_y<=y;
                  pixel<=byte1 & byte2;
               when others => null;
            end case;
            if FSM=1 then FSM<=0; else FSM<=FSM+1; end if;
         end if;
      end if;
   end process;
end SP6_X9;