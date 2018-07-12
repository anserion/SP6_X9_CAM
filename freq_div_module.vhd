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
-- Description: frequency divider
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.std_logic_unsigned.all;

entity freq_div_module is
    Port ( 
		clk   : in  STD_LOGIC;
      en    : in  STD_LOGIC;
      value : in  STD_LOGIC_VECTOR(31 downto 0);
      result: out STD_LOGIC
	 );
end freq_div_module;

architecture ax309 of freq_div_module is
   signal cnt: std_logic_vector(31 downto 0):=(others=>'0');
   signal reg_result: STD_LOGIC:='0';
begin
   result<=reg_result and en;
   process(clk)
   begin
		if rising_edge(clk)and(en='1') then
         if cnt=0 then reg_result<='1'; end if;
         if cnt=value then reg_result<='0'; end if;
         if cnt=value(30 downto 0)&'0' then cnt<=(others=>'0'); else cnt<=cnt+1; end if;
		end if;
	end process;
end ax309;
