library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SmartWatering_TB is
-- Testbenches have empty entities
end SmartWatering_TB;

architecture Behavioral of SmartWatering_TB is

    -- 1. Component Declaration (Unit Under Test)
    component SmartWateringSystem
        Port ( 
            CLK   : in  STD_LOGIC;
            reset : in  STD_LOGIC;
            M     : in  STD_LOGIC_VECTOR (2 downto 0);
            L     : in  STD_LOGIC;
            T     : in  STD_LOGIC;
            SEG   : out STD_LOGIC_VECTOR (6 downto 0);
            STATE : out STD_LOGIC_VECTOR (1 downto 0);
            M_out : out STD_LOGIC_VECTOR (2 downto 0);
            L_out : out STD_LOGIC;
            T_out : out STD_LOGIC
        );
    end component;

    -- 2. Signals for inputs (initialized to 0)
    signal CLK_tb   : STD_LOGIC := '0';
    signal reset_tb : STD_LOGIC := '0';
    signal M_tb     : STD_LOGIC_VECTOR(2 downto 0) := "000";
    signal L_tb     : STD_LOGIC := '0';
    signal T_tb     : STD_LOGIC := '0';

    -- Signals for outputs (to observe)
    signal SEG_tb   : STD_LOGIC_VECTOR(6 downto 0);
    signal STATE_tb : STD_LOGIC_VECTOR(1 downto 0);
    
    -- Clock period definition (100 MHz effectively)
    constant CLK_PERIOD : time := 10 ns;

begin

    -- 3. Instantiate the Unit Under Test (UUT)
    uut: SmartWateringSystem Port Map (
        CLK   => CLK_tb,
        reset => reset_tb,
        M     => M_tb,
        L     => L_tb,
        T     => T_tb,
        SEG   => SEG_tb,
        STATE => STATE_tb,
        M_out => open, -- We don't need to log these for the TB
        L_out => open,
        T_out => open
    );

    -- 4. Clock Process
    clk_process : process
    begin
        CLK_tb <= '0';
        wait for CLK_PERIOD/2;
        CLK_tb <= '1';
        wait for CLK_PERIOD/2;
    end process;

    -- 5. Stimulus Process (The actual test scenarios)
    stim_proc: process
    begin		
        -- ============================================================
        -- SCENARIO A: INITIALIZATION
        -- ============================================================
        report "Starting Simulation...";
        reset_tb <= '1';
        wait for 20 ns;
        reset_tb <= '0';
        wait for 20 ns;
        -- Expect: STATE "00" (Idle), SEG "0000001" ('0')

        -- ============================================================
        -- SCENARIO B: IDEAL CONDITIONS (Temp=0, Light=0)
        -- Rule: Start watering if M <= 3. Stop if M >= 7.
        -- ============================================================
        report "Test B: Ideal Conditions (T=0, L=0)";
        
        -- 1. Dry Soil (M = 2) -> Should start Watering (ST1)
        T_tb <= '0'; L_tb <= '0'; M_tb <= "010"; -- 2
        wait for 20 ns; 
        -- Expect: STATE "01" (Watering), SEG "1001000" ('H')

        -- 2. Soil getting wet (M = 5) -> Should KEEP Watering (ST1)
        M_tb <= "101"; -- 5 (Less than 7)
        wait for 20 ns;
        -- Expect: STATE "01" (Still Watering)

        -- 3. Soil Saturated (M = 7) -> Should STOP Watering (ST0)
        M_tb <= "111"; -- 7
        wait for 20 ns;
        -- Expect: STATE "00" (Idle)

        -- 4. Soil Drying slightly (M = 4) -> Should STAY Idle (ST0)
        -- (Because it only restarts if M <= 3)
        M_tb <= "100"; -- 4
        wait for 20 ns;
        -- Expect: STATE "00" (Still Idle)

        -- ============================================================
        -- SCENARIO C: NON-IDEAL CONDITIONS (Temp=1 OR Light=1)
        -- Rule: Start watering ONLY if M <= 1. Stop if M >= 3.
        -- ============================================================
        report "Test C: Non-Ideal Conditions (T=1)";
        
        -- 1. Set bad temp (T=1)
        T_tb <= '1'; L_tb <= '0'; 
        
        -- 2. Moderately Dry (M = 2) -> Should STAY Idle (ST0)
        -- (Ideally we would water, but it's too hot, so we wait)
        M_tb <= "010"; -- 2
        wait for 20 ns;
        -- Expect: STATE "00" (Idle - preserving water)

        -- 3. Critically Dry (M = 1) -> Must FORCE Watering (ST1)
        M_tb <= "001"; -- 1
        wait for 20 ns;
        -- Expect: STATE "01" (Watering emergency)

        -- 4. Soil gets slightly wet (M = 3) -> Should STOP Watering (ST0)
        -- (Stop early because conditions are bad)
        M_tb <= "011"; -- 3
        wait for 20 ns;
        -- Expect: STATE "00" (Idle)

        -- ============================================================
        -- SCENARIO D: MIXED TRANSITIONS (Switching T/L mid-operation)
        -- ============================================================
        report "Test D: Switching Conditions mid-stream";
        
        -- 1. Start Watering under Ideal conditions
        T_tb <= '0'; L_tb <= '0'; M_tb <= "000"; -- Totally dry
        wait for 20 ns;
        -- Expect: STATE "01"

        -- 2. Suddenly Night falls (L=1) while watering
        -- Current M=0. Non-Ideal Stop rule is M >= 3.
        -- Since M < 3, it should CONTINUE watering even though L=1.
        L_tb <= '1'; 
        wait for 20 ns;
        -- Expect: STATE "01" (Keep watering)

        -- 3. Moisture reaches 3 -> Should STOP now (Bad conditions threshold)
        M_tb <= "011"; -- 3
        wait for 20 ns;
        -- Expect: STATE "00" (Idle)

        report "Simulation Completed Successfully.";
        wait; -- Stop simulation
    end process;

end Behavioral;
