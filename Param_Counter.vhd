-- Simple code for an up-counter.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Param_Counter is
port(
    clk : in std_logic; -- clock input
    en  : in std_logic; -- enable input 
    rst : in std_logic; -- reset input 
    -- Counter output. Is it 18 bits to be large enough for the 100MHz clock. 
    C_out : out std_logic_vector(17 downto 0) );
end Param_Counter;

architecture Behavioral of Param_Counter is

-- Signal for the counter value. 
signal C_out_int : unsigned(17 downto 0);

begin

-- Counter process.
clk_process : process(clk)
begin
    if (rising_edge(clk)) then
        -- If reset is asserted...reset.
        if (rst = '1') then
            C_out_int <= (others => '0');
        else
            -- If the enable is asserted...count up.
            if (en = '1') then
                C_out_int <= C_out_int + 1;
            end if;
        end if;
    end if;
end process clk_process;

-- Push the counter value to the output. 
C_out <= std_logic_vector(C_out_int);

end Behavioral;
