library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SevenSegmentDecoder is
    Port ( 
        state_in : in  STD_LOGIC;                    -- 0 for ST0 (Idle), 1 for ST1 (Watering)
        seg_out  : out STD_LOGIC_VECTOR (6 downto 0) -- Active Low: 0=ON, 1=OFF (Order: a,b,c,d,e,f,g)
    );
end SevenSegmentDecoder;

architecture Behavioral of SevenSegmentDecoder is
begin
    process(state_in)
    begin
        case state_in is
            -- STATE 0: Display '0'
            -- ON: a, b, c, d, e, f | OFF: g
            when '0' => 
                seg_out <= "0000001"; 

            -- STATE 1: Display 'H'
            -- ON: b, c, e, f, g | OFF: a, d
            when '1' => 
                seg_out <= "1001000"; 
            
            -- if any Error: Display '-' (Middle segment g only)
            when others =>
                seg_out <= "1111110"; 
        end case;
    end process;
end Behavioral;
