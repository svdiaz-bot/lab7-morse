-- =============================================================================
--  Archivo : contador_medio_seg.vhd
--  Descripcion :
--     Divisor de frecuencia: genera Tick = '1' durante 1 ciclo de reloj
--     cada N ciclos. Con reloj de 50 MHz y N = 25_000_000 -> 1 tick cada 0,5 s.
--     Limpia = '1' reinicia la cuenta (para que cada punto/raya dure
--     exactamente N ciclos desde que empieza).
--     El generico N permite usar un valor pequeno en simulacion.
-- =============================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity contador_medio_seg is
    generic ( N : positive := 25_000_000 );
    port ( Clock, Reset : in  std_logic;
           Limpia       : in  std_logic;
           Tick         : out std_logic );
end entity;

architecture contador_medio_seg_arch of contador_medio_seg is
    signal cuenta : integer range 0 to N-1;
begin
    process (Clock, Reset)
    begin
        if (Reset = '0') then
            cuenta <= 0;
        elsif (Clock'event and Clock = '1') then
            if (Limpia = '1' or cuenta = N-1) then
                cuenta <= 0;
            else
                cuenta <= cuenta + 1;
            end if;
        end if;
    end process;

    Tick <= '1' when (cuenta = N-1) else '0';
end architecture;
