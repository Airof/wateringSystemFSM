library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Essential for comparing Moisture values (<=, >)

entity WateringFSM is
    Port ( 
        CLK       : in  STD_LOGIC;
        reset     : in  STD_LOGIC;
        
        -- Sensors
        M_in      : in  STD_LOGIC_VECTOR (2 downto 0); -- Moisture (0-7)
        L_in      : in  STD_LOGIC;                     -- Light (0=Ideal, 1=Bad)
        T_in      : in  STD_LOGIC;                     -- Temp  (0=Ideal, 1=Bad)
        
        -- Outputs
        state_out : out STD_LOGIC -- 0 for ST0 (Idle), 1 for ST1 (Watering)
    );
end WateringFSM;

architecture Behavioral of WateringFSM is

    -- Define States
    type state_type is (ST0, ST1);
    signal current_state, next_state : state_type;

begin

    -- --------------------------------------------------------
    -- Process 1: Synchronous Logic (Registers)
    -- Handles Reset and Clock Edges
    -- --------------------------------------------------------
    sync_proc: process(CLK, reset)
    begin
        if (reset = '1') then
            current_state <= ST0; -- Reset to Idle
        elsif rising_edge(CLK) then
            current_state <= next_state;
        end if;
    end process;

    -- --------------------------------------------------------
    -- Process 2: Combinational Logic (Next State Logic)
    -- Decides the next state based on inputs and rules
    -- --------------------------------------------------------
    comb_proc: process(current_state, M_in, L_in, T_in)
        variable M_val : integer; -- Helper variable for cleaner comparisons
    begin
        -- Convert std_logic_vector to integer for easier comparison (0 to 7)
        M_val := to_integer(unsigned(M_in));
        
        -- Default: Stay in current state (prevents latches)
        next_state <= current_state;

        case current_state is
        
            -- STATE 0: IDLE (No Watering)
            when ST0 =>
                state_out <= '0';
                
                -- Check for Ideal Conditions (Temp=0 AND Light=0)
                if (T_in = '0' and L_in = '0') then
                    -- Rule: If M <= 3, Start Watering 
                    if (M_val <= 3) then
                        next_state <= ST1;
                    else
                        next_state <= ST0; -- Explicit stay 
                    end if;
                    
                -- Check for Non-Ideal Conditions (Temp=1 OR Light=1)
                else 
                    -- Rule: If M <= 1 (Critically Dry), Start Watering 
                    if (M_val <= 1) then
                        next_state <= ST1;
                    else
                        next_state <= ST0; -- Explicit stay 
                    end if;
                end if;

            -- STATE 1: WATERING
            when ST1 =>
                state_out <= '1';
                
                -- Check for Ideal Conditions
                if (T_in = '0' and L_in = '0') then
                    -- Rule: If M >= 7 (Saturated), Stop Watering 
                    if (M_val >= 7) then
                        next_state <= ST0;
                    else
                        next_state <= ST1; -- Keep watering 
                    end if;
                    
                -- Check for Non-Ideal Conditions
                else
                    -- Rule: If M >= 3 (Moderately Wet), Stop Watering 
                    -- (Don't waste water in bad conditions if soil is barely okay)
                    if (M_val >= 3) then
                        next_state <= ST0;
                    else
                        next_state <= ST1; -- Keep watering 
                    end if;
                end if;

        end case;
    end process;

end Behavioral;
