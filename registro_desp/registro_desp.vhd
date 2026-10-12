-- =============================================================================
--  Archivo : registro_desp.vhd
--  Descripcion :
--     Registro de desplazamiento de 4 bits con carga paralela.
--     Carga = '1'    -> Q <= D (patron de la letra)
--     Desplaza = '1' -> desplaza a la izquierda (entra '0' por la derecha)
--     Simbolo = Q(3) -> simbolo actual ('0' punto, '1' raya)
--     Reset asincrono activo en bajo.
-- =============================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity registro_desp is
    port ( Clock, Reset    : in  std_logic;
           Carga, Desplaza : in  std_logic;
           D               : in  std_logic_vector(3 downto 0);
           Simbolo         : out std_logic );
end entity;

architecture registro_desp_arch of registro_desp is
    signal Q : std_logic_vector(3 downto 0);
begin
    process (Clock, Reset)
    begin
        if (Reset = '0') then
            Q <= (others => '0');
        elsif (Clock'event and Clock = '1') then
            if (Carga = '1') then
                Q <= D;
            elsif (Desplaza = '1') then
                Q <= Q(2 downto 0) & '0';
            end if;
        end if;
    end process;

    Simbolo <= Q(3);
end architecture;
