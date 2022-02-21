
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Param_Counter is
port(
    clk : in std_logic;
    en  : in std_logic;
    rst : in std_logic;
    C_out : out std_logic_vector(17 downto 0) );
end Param_Counter;

architecture Behavioral of Param_Counter is

signal C_out_int : unsigned(17 downto 0);

begin

clk_process : process(clk)
begin
    if (rising_edge(clk)) then
        if (rst = '1') then
            C_out_int <= (others => '0');
        else
            if (en = '1') then
                C_out_int <= C_out_int + 1;
            end if;
        end if;
    end if;
end process clk_process;

C_out <= std_logic_vector(C_out_int);

end Behavioral;
