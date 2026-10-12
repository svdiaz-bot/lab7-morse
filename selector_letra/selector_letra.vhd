-- =============================================================================
--  Archivo : selector_letra.vhd
--  Descripcion :
--     Logica de seleccion de letra (memoria ROM de 8 posiciones).
--     A partir de SW2-0 entrega el patron Morse y su longitud.
--
--     Patron: 4 bits, el simbolo que se envia primero esta en el bit 3 (MSB).
--             '0' = punto (.)   '1' = raya (-)   (bits sobrantes en '0')
--
--     SW  Letra  Morse   Patron  Longitud
--     000   A    .-       0100      2
--     001   B    -...     1000      4
--     010   C    -.-.     1010      4
--     011   D    -..      1000      3
--     100   E    .        0000      1
--     101   F    ..-.     0010      4
--     110   G    --.      1100      3
--     111   H    ....     0000      4
-- =============================================================================
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity selector_letra is
    port ( Letra    : in  std_logic_vector(2 downto 0);
           Patron   : out std_logic_vector(3 downto 0);
           Longitud : out std_logic_vector(2 downto 0) );
end entity;

architecture selector_letra_arch of selector_letra is

    type ROM_patron   is array (0 to 7) of std_logic_vector(3 downto 0);
    type ROM_longitud is array (0 to 7) of std_logic_vector(2 downto 0);

    constant PATRONES : ROM_patron := (0 => "0100",   -- A  .-
                                       1 => "1000",   -- B  -...
                                       2 => "1010",   -- C  -.-.
                                       3 => "1000",   -- D  -..
                                       4 => "0000",   -- E  .
                                       5 => "0010",   -- F  ..-.
                                       6 => "1100",   -- G  --.
                                       7 => "0000");  -- H  ....

    constant LONGITUDES : ROM_longitud := (0 => "010",   -- A  2
                                           1 => "100",   -- B  4
                                           2 => "100",   -- C  4
                                           3 => "011",   -- D  3
                                           4 => "001",   -- E  1
                                           5 => "100",   -- F  4
                                           6 => "011",   -- G  3
                                           7 => "100");  -- H  4
begin
    Patron   <= PATRONES  (to_integer(unsigned(Letra)));
    Longitud <= LONGITUDES(to_integer(unsigned(Letra)));
end architecture;
