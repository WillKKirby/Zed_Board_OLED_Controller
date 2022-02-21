--
-- Logic block for the initalistion of the OLED display. 
-- This block is run when the system starts or when reset. 
-- It runs through the start up initalistion of the display, 
--  letting the system know when it is complete. 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity OLED_CONTROLLER_IP_v1_0_SPI_INIT is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           done : out STD_LOGIC;
           WR_DONE : in STD_LOGIC;
           SPI_en  : out std_logic;
           OLED_SDIN : out STD_LOGIC_VECTOR(7 downto 0);
           OLED_DC : out STD_LOGIC;
           OLED_RES : out STD_LOGIC;
           OLED_VBAT : out STD_LOGIC;
           OLED_VDD : out STD_LOGIC);
end OLED_CONTROLLER_IP_v1_0_SPI_INIT;

architecture Behavioral of OLED_CONTROLLER_IP_v1_0_SPI_INIT is

-- Signals for internal versions of the outputs. This allows them to have inital values. 
signal OLED_SDIN_int : std_logic_vector(7 downto 0); 
signal OLED_DC_int   : std_logic := '0';
signal OLED_RES_int  : std_logic := '1';
signal OLED_VBAT_int : std_logic := '1';
signal OLED_VDD_int  : std_logic := '1';
 
-- States and signals for the FSM.
type fsm_states is (idle, WAIT_STATE, WR_WAIT_STATE, VDDOn, DispOff, ResetOn, 
                    ResetOff, ChargePump1, ChargePump2, PreCharge1, PreCharge2, 
                    VBatOn, DispContrast1, DispContrast2, InvertDisp1, 
                    InvertDisp2, ComConfig1, ComConfig2, DispOn, DONE_STATE, TEST_STATE);
-- The state machine works by:
-- The state holds the current clock periods state.
-- The next_state holds the following clock periods state. 
-- The held_state holds the proceeding state after a wait period.
--  This allows the state machine to use the same wait states multiple times, 
--  while keeping a memory of where it needs to return to in the state progression.
signal state, next_state, held_state : fsm_states;

-- Signals for the counter (timer).
-- Enable and reset signals.
signal CT_en, CT_rst : std_logic;
-- A signal to hole the output of the coutner. 
signal CT_out : std_logic_Vector(17 downto 0);
-- A signal for altering the FSM when the counter has finished counting. 
signal CT_DONE : std_logic;
-- Signal for the counter limit value.
signal CT_limit : std_logic_Vector(17 downto 0);

begin

-- Counter entity for the wait states.
Counter : entity work.Param_Counter
port map (
    clk => clk, 
    en => CT_en, 
    rst => CT_rst,
    C_out => CT_out );

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

-- State Change Logic 
State_Logic_Pro : process(state, WR_DONE, CT_DONE, en, held_state)
begin
    case state is
        
        -- When in idle, wait until there is an enable for the init.
        when idle =>
        
            if (en = '1') then
                next_state <= VDDOn;
            else
                next_state <= state;
            end if;
        
        -- This wait state is not for when data is written, and is just for when a pause is needed. 
        when WAIT_STATE =>
            
            if (CT_DONE = '1') then
                next_state <= held_state;
            else 
                next_state <= state;
            end if;
        
        -- This wait state waits until the data is written to the OLED display before carrying on. 
        when WR_WAIT_STATE =>
            
             if (WR_DONE = '1') then 
                next_state <= held_state;
             else
                next_state <= state;
             end if;   
        
        when VDDOn =>
            
            next_state <= WAIT_STATE;
            held_state <= DispOff;
        
        when DispOff =>
        
            next_state <= WR_WAIT_STATE;
            held_state <= ResetOn;
        
        when ResetOn =>
            
            next_state <= WAIT_STATE;
            held_state <= ResetOff;
            
        when ResetOff =>
            
            next_state <= WAIT_STATE;
            held_state <= ChargePump1;
            
        when ChargePump1 => 
            
            next_state <= WR_WAIT_STATE;
            held_state <= ChargePump2;
            
        when ChargePump2 =>
            
            next_state <= WR_WAIT_STATE;
            held_state <= PreCharge1;
        
        when PreCharge1 => 
            
            next_state <= WR_WAIT_STATE;
            held_state <= PreCharge2;
        
        when PreCharge2 =>
        
            next_state <= WR_WAIT_STATE;
            held_state <= VBatOn;
            
        when VBatOn => 
            
            next_state <= WAIT_STATE;
            held_state <= DispContrast1;
            
        when DispContrast1 =>
        
            next_state <= WR_WAIT_STATE;
            held_state <= DispContrast2;
            
        when DispContrast2 => 
        
            next_state <= WR_WAIT_STATE;
            held_state <= InvertDisp1;
            
        when InvertDisp1 => 
            
            next_state <= WR_WAIT_STATE;
            held_state <= InvertDisp2;
            
        when InvertDisp2 => 
            
            next_state <= WR_WAIT_STATE;
            held_state <= ComConfig1;
            
        when ComConfig1 =>
        
            next_state <= WR_WAIT_STATE;
            held_state <= ComConfig2;
        
        when ComConfig2 => 
            
            next_state <= WR_WAIT_STATE;
            held_state <= DispOn;
            
        when DispOn => 
            
            next_state <= WR_WAIT_STATE;
            held_state <= TEST_STATE;
            
        when TEST_STATE =>
        
            next_state <= WR_WAIT_STATE;
            held_state <= DONE_STATE;
        
        when DONE_STATE =>
        
            next_state <= state;
            
   end case;
end process State_Logic_Pro;


-- Logic for the signals based on the FSM.

-----------------------------
-- Counter Related Signals -- 
-----------------------------

-- Setting the limit for the counter for the wait states.
CT_limit <= "110000110101000000"; -- Temp setting; this is 2ms for a 100MHz clock. 

-- Setting the CT_DONE signal.
CT_DONE <= '1' when CT_limit = CT_out else '0';
-- Setting the counter to run when it is in a wait state, 
--  and to reset to 0 when not in a wait state. 
CT_en <= '1' when state = WAIT_STATE else '0';
-- Simply resetting the clock when it isn't being used. 
CT_RST <= not CT_en;

-- ** -- 

-- Setting the data/control signal to 0 (LOW) it will treat the inputs as controls.
--  (note when setting it high to '1' it will treat inputs as data)
OLED_DC_int <= '1' when state = idle else '0';  

-- Setting VDD to 0, when in the state VDDOn. 
OLED_VDD_int <= '0' when state = VDDOn;

-- Set the SPI enable, ie to write to the screen when in the, 
--  WR_WAIT_STATE. Only have this when in this state however.
SPI_en <= '1' when state = WR_WAIT_STATE else '0';

-- When the reset state is used, send the OLED_RES signal. 
OLED_RES_int <= '0' when state = ResetOn else
                '1' when state = ResetOff;


-- Section for writing the data to the LED Display.
-- These are all control insturctions for the initalisation of the display. 
OLED_SDIN_int <= "10101110" when state = DispOff or held_state = ResetOn else             -- 0xAE
                 "10001101" when state = ChargePump1 or held_state = ChargePump2 else     -- 0x8D
                 "00010100" when state = ChargePump2 or held_state = PreCharge1 else      -- 0x14
                 "11011001" when state = PreCharge1 or held_state = PreCharge2 else       -- 0xD9
                 "11110001" when state = PreCharge2 or held_state = VBatOn else           -- 0xF1
                 "10000001" when state = DispContrast1 or held_state = DispContrast2 else -- 0x81
                 "00001111" when state = DispContrast2 or held_state = InvertDisp1 else   -- 0x0F
                 "10100000" when state = InvertDisp1 or held_state = InvertDisp2 else     -- 0xA0
                 "11000000" when state = InvertDisp2 or held_state = ComConfig1 else      -- 0xC0
                 "11011010" when state = ComConfig1 or held_state = ComConfig2 else       -- 0xDA
                 "00000000" when state = ComConfig2 or held_state = DispOn else           -- 0x00
                 "10101111" when state = DispOn or held_state = TEST_STATE else           -- 0xAF
                 "10100101" when state = TEST_STATE or held_state = DONE_STATE;           -- 0xA5

-- The VBAT signal is set to '1' when it is initalised. 
-- This is necessary, but beyond this point it is set to 0.              
OLED_VBAT_int <= '0' when state = VBatOn;

-- Done signal from the initaisation of the OLED display.
done <= '1' when state = DONE_STATE else '0';

-- Push the internal signals to the output. 
OLED_SDIN <= OLED_SDIN_int;
OLED_DC <= OLED_DC_int;
OLED_RES <= OLED_RES_int;
OLED_VBAT <= OLED_VBAT_int;
OLED_VDD <= OLED_VDD_int;

end Behavioral;
