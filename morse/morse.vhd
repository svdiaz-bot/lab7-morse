-- =============================================================================
--  Laboratorio 7 - Parte IV : Codificador de codigo Morse 
-- =============================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity morse is
    generic ( N_MEDIO_SEG : positive := 25_000_000 );   -- 0,5 s a 50 MHz
    port ( CLOCK_50 : in  std_logic;
           KEY      : in  std_logic_vector(1 downto 0);
           SW       : in  std_logic_vector(2 downto 0);
           LEDR     : out std_logic_vector(9 downto 0) );
end entity;

architecture morse_arch of morse is

    -- ---------------- Declaracion de componentes ----------------
    component morse_fsm
        port ( Clock, Reset                  : in  std_logic;
               Start, Tick, Simbolo, CntCero : in  std_logic;
               LED, Carga, Desplaza          : out std_logic;
               Decrementa, Limpia, Ocupado   : out std_logic );
    end component;

    component selector_letra
        port ( Letra    : in  std_logic_vector(2 downto 0);
               Patron   : out std_logic_vector(3 downto 0);
               Longitud : out std_logic_vector(2 downto 0) );
    end component;

    component registro_desp
        port ( Clock, Reset    : in  std_logic;
               Carga, Desplaza : in  std_logic;
               D               : in  std_logic_vector(3 downto 0);
               Simbolo         : out std_logic );
    end component;

    component contador_longitud
        port ( Clock, Reset      : in  std_logic;
               Carga, Decrementa : in  std_logic;
               D                 : in  std_logic_vector(2 downto 0);
               Cero              : out std_logic );
    end component;

    component contador_medio_seg
        generic ( N : positive := 25_000_000 );
        port ( Clock, Reset : in  std_logic;
               Limpia       : in  std_logic;
               Tick         : out std_logic );
    end component;

    -- ---------------- Senales internas ----------------
    signal Clock, Resetn                 : std_logic;
    signal key1_s1, key1_s2, Start       : std_logic;
    signal Patron                        : std_logic_vector(3 downto 0);
    signal Longitud                      : std_logic_vector(2 downto 0);
    signal Simbolo, CntCero, Tick        : std_logic;
    signal Carga, Desplaza, Decrementa   : std_logic;
    signal Limpia, LED, Ocupado          : std_logic;

begin

    Clock  <= CLOCK_50;
    Resetn <= KEY(0);                
    SYNC_KEY1 : process (Clock, Resetn)
    begin
        if (Resetn = '0') then
            key1_s1 <= '1';
            key1_s2 <= '1';
        elsif (Clock'event and Clock = '1') then
            key1_s1 <= KEY(1);
            key1_s2 <= key1_s1;
        end if;
    end process;
    Start <= not key1_s2;

    -- ---------------- Instancias ----------------
    U_SEL : selector_letra
        port map ( Letra => SW, Patron => Patron, Longitud => Longitud );

    U_REG : registro_desp
        port map ( Clock => Clock, Reset => Resetn,
                   Carga => Carga, Desplaza => Desplaza,
                   D => Patron, Simbolo => Simbolo );

    U_CNT : contador_longitud
        port map ( Clock => Clock, Reset => Resetn,
                   Carga => Carga, Decrementa => Decrementa,
                   D => Longitud, Cero => CntCero );

    U_TICK : contador_medio_seg
        generic map ( N => N_MEDIO_SEG )
        port map ( Clock => Clock, Reset => Resetn,
                   Limpia => Limpia, Tick => Tick );

    U_FSM : morse_fsm
        port map ( Clock => Clock, Reset => Resetn,
                   Start => Start, Tick => Tick,
                   Simbolo => Simbolo, CntCero => CntCero,
                   LED => LED, Carga => Carga, Desplaza => Desplaza,
                   Decrementa => Decrementa, Limpia => Limpia,
                   Ocupado => Ocupado );

    -- ---------------- Salidas ----------------
    LEDR(0)          <= LED;
    LEDR(8 downto 1) <= (others => '0');
    LEDR(9)          <= Ocupado;

end architecture;