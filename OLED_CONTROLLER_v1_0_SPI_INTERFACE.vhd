-- Design Title - SPI Interface.
-- Designer - Will Kirby.
--
-- This component takes a byte of data and send it a byte at a time to the OLED display.
-- It uses a shift register to send a single bit at a time. 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity OLED_CONTROLLER_IP_v1_0_SPI_INTERFACE is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en  : in STD_LOGIC;
           WR_DONE : out STD_LOGIC;
           OLED_SDIN_int : in STD_LOGIC_VECTOR (7 downto 0);  -- Byte of data to be outputted. 
           OLED_SCLK    : out std_logic;
           OLED_SDIN : out STD_LOGIC );   -- Serial data to be outputted.
end OLED_CONTROLLER_IP_v1_0_SPI_INTERFACE;

architecture Behavioral of OLED_CONTROLLER_IP_v1_0_SPI_INTERFACE is

-- States for the FSM.
type fsm_states is (idle, Send_Data, Done);
signal state, next_state : fsm_states;

signal shift_reg : std_logic_vector(7 downto 0);     -- Shifts around to send out the data.
signal shift_counter : unsigned(3 downto 0); -- Count the number of shifts.
signal CLK_Divider : std_logic; -- This will divide the clk for the PL side down to one for the SPI data transfer.
signal CLK_Divider_Counter : std_logic_vector(17 downto 0);
signal OLED_SDATA_int : std_logic;

signal falling : std_logic := '0';

signal CT_en, Ct_rst : std_logic;

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
        
        when idle =>
            
            if (en = '1') then
                next_state <= Send_Data;
            else
                next_state <= state;
            end if;
        
        when Send_Data =>
        
            if (shift_counter = "1000" and falling = '0') then
                next_state <= Done;
            else
                next_state <= state;
            end if;
        
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

SPI_Send_byte : process(clk)
begin
    if rising_edge(clk) then
        if (state = idle) then
            shift_counter <= (others => '0');
            shift_reg <= OLED_SDIN_int;
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
