-- =============================================================================
--  Archivo : contador_longitud.vhd
--  Descripcion :
--     Contador descendente de 3 bits: cuantos simbolos faltan por enviar.
--     Carga = '1'      -> cuenta <= D (longitud de la letra)
--     Decrementa = '1' -> cuenta <= cuenta - 1
--     Cero = '1' cuando cuenta = 0
--     Reset asincrono activo en bajo.
-- =============================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity contador_longitud is
    port ( Clock, Reset      : in  std_logic;
           Carga, Decrementa : in  std_logic;
           D                 : in  std_logic_vector(2 downto 0);
           Cero              : out std_logic );
end entity;

architecture contador_longitud_arch of contador_longitud is
    signal cuenta : unsigned(2 downto 0);
begin
    process (Clock, Reset)
    begin
        if (Reset = '0') then
            cuenta <= (others => '0');
        elsif (Clock'event and Clock = '1') then
            if (Carga = '1') then
                cuenta <= unsigned(D);
            elsif (Decrementa = '1' and cuenta /= 0) then
                cuenta <= cuenta - 1;
            end if;
        end if;
    end process;

    Cero <= '1' when (cuenta = 0) else '0';
end architecture;
