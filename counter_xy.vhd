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
-- Description: double XY counter
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity counter_xy is
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
end counter_xy;

architecture SP6_X9 of counter_xy is
signal x_reg: std_logic_vector (n-1 downto 0):=conv_std_logic_vector(x_min,n);
signal y_reg: std_logic_vector (n-1 downto 0):=conv_std_logic_vector(y_min,n);
begin
	
   process(clk)
   begin
		if rising_edge(clk) then
         if reset='1' then
            x_reg<=conv_std_logic_vector(x_min,n);
            y_reg<=conv_std_logic_vector(y_min,n);
         end if;
         if en='1' then
            if x_reg=conv_std_logic_vector(x_max,n) then
               x_reg<=conv_std_logic_vector(x_min,n);
               if y_reg=conv_std_logic_vector(y_max,n) then
                  y_reg<=conv_std_logic_vector(y_min,n);
               else
                  y_reg<=y_reg+1;
               end if;
            else
               x_reg<=x_reg+1;
            end if;
         end if;
		end if;
	end process;
   x<=x_reg;
   y<=y_reg;
end SP6_X9;