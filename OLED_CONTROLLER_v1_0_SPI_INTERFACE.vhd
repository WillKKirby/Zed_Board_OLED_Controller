-- Design Title - SPI Interface.
-- Designer - Will Kirby.
-- 
-- This code is inspried by codes from mmattioli - https://github.com/mmattioli/ZedBoard-OLED.
--
-- This component takes a byte of data and send it a byte at a time to the OLED display.
-- It uses a shift register to send a single bit at a time. 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OLED_CONTROLLER_IP_v1_0_SPI_INTERFACE is
    Port ( clk : in STD_LOGIC; -- Clock input 
           rst : in STD_LOGIC; -- Reset input
           en  : in STD_LOGIC; -- Enable input 
           WR_DONE : out STD_LOGIC; -- Flag to indicate when the write is complete. 
           OLED_SDIN_int : in STD_LOGIC_VECTOR (7 downto 0);  -- Byte of data to be outputted. 
           OLED_SCLK    : out std_logic; -- The clock signal for the SPI interface.
           OLED_SDIN : out STD_LOGIC );   -- Serial data to be outputted.
end OLED_CONTROLLER_IP_v1_0_SPI_INTERFACE;

architecture Behavioral of OLED_CONTROLLER_IP_v1_0_SPI_INTERFACE is

-- States for the FSM.
-- The logic will wait in idle until a write is requested, 
--  it will then write the data and move to the "done" state when it is complete.
type fsm_states is (idle, Send_Data, Done);
signal state, next_state : fsm_states;

signal shift_reg : std_logic_vector(7 downto 0);     -- Shifts around to send out the data.
signal shift_counter : unsigned(3 downto 0); -- Count the number of shifts.
signal CLK_Divider : std_logic; -- This will divide the clk for the PL side down to one for the SPI data transfer.
signal CLK_Divider_Counter : std_logic_vector(17 downto 0); -- This enables the clock when the counter reaches 32.
signal OLED_SDATA_int : std_logic;  -- This is the bit of data that is written to the OLED.

signal falling : std_logic := '0'; -- Signal to determine when the clock period is falling, hense when to write data. 

signal CT_en, CT_rst : std_logic; -- signals for the enable and reset for the internal counter. 

begin

-- Signals for the clk logic.
-- This divides the current clock from the ZED board pin - 100MHz/32 -> 3.12MHz
CLK_Divider <= not CLK_Divider_Counter(4);
OLED_SCLK <= CLK_Divider;

-- Send the data from the logic to the display.
OLED_SDIN <= OLED_SDATA_int;

-- Send the done signal, indicaing that the write to the OLED is complete. 
WR_DONE <= '1' when state = DONE else '0';

-- FSM Processes.

-- Process for the FSM to change states,
Change_State_Pro : process (clk)
begin
    if (rising_edge(clk)) then
        if (rst = '1') then    
            state <= idle;
        else
            state <= next_State;
        end if;
    end if;
end process Change_State_Pro;

-- FSM Logic Process.
State_Tranfer_Logic_Pro : process(state, en, shift_counter, falling)
begin

    case state is
        
        -- Waits in the reset state, idle.
        when idle =>
            
            if (en = '1') then
                next_state <= Send_Data;
            else
                next_state <= state;
            end if;
        
        -- This state when writing data. 
        when Send_Data =>
            
            -- Move state when all the bits of data have been written.
            if (shift_counter = "1000" and falling = '0') then
                next_state <= Done;
            else
                next_state <= state;
            end if;
        
        -- State when the write is complete. 
        -- Waits in here until the enable drops, then back to idle. 
        when Done => 
        
            if (en = '0') then
                next_state <= idle;
            else
                next_state <= state;
            end if;
        
    end case;
    
end process State_Tranfer_Logic_Pro;

-- Counter for the clock division.
Clock_Divider : entity work.Param_Counter
port map (
    clk => clk, 
    rst => CT_rst, 
    en => CT_en, 
    C_out => CLK_Divider_Counter );

-- Always have the counter running. 
CT_en <= en;
CT_rst <= '1' when unsigned(CLK_Divider_Counter) > 32 or rst = '1' or state = idle else '0'; 

-- This is a little bit of a messy process.
SPI_Send_byte : process(clk)
begin
    -- On the rising edge of the clock, check the states. 
    if rising_edge(clk) then
        -- If the state is idle, then reset the shift counter, and shift reg.
        if (state = idle) then
            shift_counter <= (others => '0');
            shift_reg <= OLED_SDIN_int;
        -- If the state is in the sending data state, 
        --  check if the clock edge is falling. If so -> Send a bit, and update the shift reg. 
        -- if the clock isn't falling, then make the update the clock to be falling on the next bit.
        elsif (state = Send_Data) then
            if (CLK_Divider = '0' and falling = '0') then
                falling <= '1';
                OLED_SDATA_int <= shift_reg(7);
                shift_reg <= shift_reg(6 downto 0) & '0';
                shift_counter <= shift_counter + 1;
            elsif (CLK_Divider = '1') then
                falling <= '0';
            end if;
        end if;
    end if;
end process SPI_Send_byte;
                
end Behavioral;
