-- =============================================================================
--  Archivo : morse_fsm_TB.vhd
--  Descripcion :
--     Testbench de la FSM (morse_fsm) aislada.
--     Se manejan directamente las entradas de la FSM (Start, Tick, Simbolo,
--     CntCero) y se verifica con ASSERT la salida de cada estado.
--     Se recorre la letra A ( . - ):  punto, pausa, raya (3 ticks), pausa, fin.
--     Ademas se prueba que KEY1 sostenido no repite la letra y el reset
--     asincrono en medio de una transmision.
--
--     Reloj de 50 MHz (periodo 20 ns).
-- =============================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity morse_fsm_TB is
end entity;

architecture morse_fsm_TB_arch of morse_fsm_TB is

    -- Declaracion del componente (DUT)
    component morse_fsm
        port ( Clock, Reset                  : in  std_logic;
               Start, Tick, Simbolo, CntCero : in  std_logic;
               LED, Carga, Desplaza          : out std_logic;
               Decrementa, Limpia, Ocupado   : out std_logic );
    end component;

    -- Senales del testbench
    constant T : time := 20 ns;                       -- 50 MHz

    signal Clock_TB   : std_logic := '0';
    signal Reset_TB   : std_logic := '0';
    signal Start_TB, Tick_TB, Simbolo_TB, CntCero_TB  : std_logic := '0';
    signal LED_TB, Carga_TB, Desplaza_TB              : std_logic;
    signal Decrementa_TB, Limpia_TB, Ocupado_TB       : std_logic;
    signal fin_sim    : boolean := false;

begin

    -- Instancia del DUT
    DUT1 : morse_fsm
        port map ( Clock => Clock_TB, Reset => Reset_TB,
                   Start => Start_TB, Tick => Tick_TB,
                   Simbolo => Simbolo_TB, CntCero => CntCero_TB,
                   LED => LED_TB, Carga => Carga_TB, Desplaza => Desplaza_TB,
                   Decrementa => Decrementa_TB, Limpia => Limpia_TB,
                   Ocupado => Ocupado_TB );

    -- Generacion del reloj
    CLOCK_GEN : process
    begin
        if fin_sim then
            wait;
        end if;
        Clock_TB <= '0'; wait for T/2;
        Clock_TB <= '1'; wait for T/2;
    end process;

    -- Generacion de estimulos y verificacion
    STIMULUS : process

        variable errores : integer := 0;

        -- espera n flancos de subida y muestrea 1 ns despues
        procedure ciclos (n : in positive) is
        begin
            for i in 1 to n loop
                wait until rising_edge(Clock_TB);
            end loop;
            wait for 1 ns;
        end procedure;

        -- un pulso de Tick de un ciclo (como el contador de medio segundo)
        procedure pulso_tick is
        begin
            Tick_TB <= '1';
            ciclos(1);
            Tick_TB <= '0';
        end procedure;

        -- verifica las salidas esperadas
        procedure verificar (paso : in string;
                             led, carga, desp, dec, limp, ocup : in std_logic) is
        begin
            if (LED_TB /= led or Carga_TB /= carga or Desplaza_TB /= desp or
                Decrementa_TB /= dec or Limpia_TB /= limp or Ocupado_TB /= ocup) then
                report "ERROR en " & paso severity error;
                errores := errores + 1;
            else
                report "OK   " & paso severity note;
            end if;
        end procedure;

    begin
        --                              LED Car Des Dec Lim Ocu
        -- Reset
        Reset_TB <= '0';
        ciclos(2);
        verificar("reset -> sEspera",   '0','0','0','0','1','0');
        Reset_TB <= '1';
        ciclos(3);
        verificar("sEspera sin KEY1",   '0','0','0','0','1','0');

        -- ===== Letra A ( . - ) : longitud 2 =====
        Simbolo_TB <= '0';  CntCero_TB <= '0';
        Start_TB   <= '1';                       -- se presiona KEY1
        ciclos(1);
        verificar("sCargar",            '0','1','0','0','1','1');
        Start_TB   <= '0';                       -- se suelta KEY1
        ciclos(1);
        verificar("sEvaluar",           '0','0','0','0','1','1');
        ciclos(1);
        verificar("sPunto",             '1','0','0','0','0','1');
        ciclos(5);                               -- sin tick: se queda en punto
        verificar("sPunto (espera)",    '1','0','0','0','0','1');
        pulso_tick;
        verificar("sPausa",             '0','0','0','0','0','1');
        pulso_tick;
        verificar("sSiguiente",         '0','0','1','1','0','1');

        Simbolo_TB <= '1';                       -- el registro desplazado muestra raya
        ciclos(1);
        verificar("sEvaluar (2)",       '0','0','0','0','1','1');
        ciclos(1);
        verificar("sRaya1",             '1','0','0','0','0','1');
        pulso_tick;
        verificar("sRaya2",             '1','0','0','0','0','1');
        pulso_tick;
        verificar("sRaya3",             '1','0','0','0','0','1');
        pulso_tick;
        verificar("sPausa (2)",         '0','0','0','0','0','1');
        pulso_tick;
        verificar("sSiguiente (2)",     '0','0','1','1','0','1');

        CntCero_TB <= '1';  Simbolo_TB <= '0';   -- ya no quedan simbolos
        ciclos(1);
        verificar("sEvaluar (3)",       '0','0','0','0','1','1');
        ciclos(1);
        verificar("sFin",               '0','0','0','0','0','0');
        ciclos(1);
        verificar("sEspera (fin A)",    '0','0','0','0','1','0');

        -- ===== KEY1 sostenido: solo una transmision =====
        CntCero_TB <= '0';  Simbolo_TB <= '0';
        Start_TB   <= '1';
        ciclos(2);                               -- sCargar, sEvaluar
        CntCero_TB <= '1';                       -- simula letra terminada
        ciclos(1);
        verificar("sFin con KEY1",      '0','0','0','0','0','0');
        ciclos(10);
        verificar("sFin sostenido",     '0','0','0','0','0','0');
        Start_TB   <= '0';
        ciclos(1);
        verificar("sEspera al soltar",  '0','0','0','0','1','0');

        -- ===== Reset asincrono durante una raya =====
        CntCero_TB <= '0';  Simbolo_TB <= '1';
        Start_TB   <= '1';
        ciclos(3);                               -- sCargar, sEvaluar, sRaya1
        Start_TB   <= '0';
        verificar("sRaya1 (antes rst)", '1','0','0','0','0','1');
        wait for 5 ns;
        Reset_TB   <= '0';                       -- reset entre flancos
        wait for 1 ns;
        verificar("reset asincrono",    '0','0','0','0','1','0');
        Reset_TB   <= '1';
        ciclos(2);

        -- Resultado final
        if errores = 0 then
            report "==== morse_fsm_TB: TODAS LAS PRUEBAS PASARON ====" severity note;
        else
            report "==== morse_fsm_TB: " & integer'image(errores) & " ERRORES ====" severity failure;
        end if;
        fin_sim <= true;
        wait;
    end process;

end architecture;
