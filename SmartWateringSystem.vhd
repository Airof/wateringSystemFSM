library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SmartWateringSystem is
    Port ( 
        -- Inputs (from FPGA Board)
        CLK       : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        M         : in  STD_LOGIC_VECTOR (2 downto 0); -- Moisture Sensor
        L         : in  STD_LOGIC;                     -- Light Sensor
        T         : in  STD_LOGIC;                     -- Temp Sensor
        
        -- Outputs (to FPGA Board)
        SEG       : out STD_LOGIC_VECTOR (6 downto 0); -- 7-Segment Display
        STATE     : out STD_LOGIC_VECTOR (1 downto 0); -- Binary State (00 or 01)
        
        -- Status LEDs (Pass-through inputs to LEDs for visualization)
        M_out     : out STD_LOGIC_VECTOR (2 downto 0);
        L_out     : out STD_LOGIC;
        T_out     : out STD_LOGIC
    );
end SmartWateringSystem;

architecture Behavioral of SmartWateringSystem is

    -- 1. Component Declaration: WateringFSM
    component WateringFSM
        Port ( 
            CLK       : in  STD_LOGIC;
            reset     : in  STD_LOGIC;
            M_in      : in  STD_LOGIC_VECTOR (2 downto 0);
            L_in      : in  STD_LOGIC;
            T_in      : in  STD_LOGIC;
            state_out : out STD_LOGIC
        );
    end component;

    -- 2. Component Declaration: SevenSegmentDecoder
    component SevenSegmentDecoder
        Port ( 
            state_in : in  STD_LOGIC;
            seg_out  : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component;

    -- Internal Signals (The wires connecting components)
    signal fsm_state_signal : STD_LOGIC; -- Carries the 0 or 1 from FSM to Decoder

begin

    -- ------------------------------------------------------------
    -- Instantiation 1: The Finite State Machine (The Brain)
    -- ------------------------------------------------------------
    U1_FSM: WateringFSM
    port map (
        CLK       => CLK,
        reset     => reset,
        M_in      => M,
        L_in      => L,
        T_in      => T,
        state_out => fsm_state_signal  -- Connect output to internal wire
    );

    -- ------------------------------------------------------------
    -- Instantiation 2: The Decoder (The Display Driver)
    -- ------------------------------------------------------------
    U2_Decoder: SevenSegmentDecoder
    port map (
        state_in => fsm_state_signal, -- Input comes from the FSM wire
        seg_out  => SEG               -- Output goes to physical pins
    );

    -- ------------------------------------------------------------
    -- Output Assignments
    -- ------------------------------------------------------------
    
    -- Drive the Status LEDs (Direct pass-through)
    M_out <= M;
    L_out <= L;
    T_out <= T;

    -- Drive the Binary State Output (00 or 01)
    -- We append a '0' because the FSM only uses 1 bit (0/1), but STATE is 2-bit.
    STATE <= "0" & fsm_state_signal; 

end Behavioral;
