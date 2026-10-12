-- =============================================================================
--  Laboratorio 7 - Parte IV : Codificador de codigo Morse
--  Archivo : morse_fsm.vhd
--  Descripcion :
--     Maquina de estados finitos (FSM) de control del codificador Morse.
--     Maquina tipo MOORE descrita con los TRES procesos vistos en clase:
--        1) STATE_MEMORY     -> memoria de estado (registro, reset asincrono)
--        2) NEXT_STATE_LOGIC -> logica de transicion de estados
--        3) OUTPUT_LOGIC     -> logica de salida
--
--  Tiempos (1 tick = 0,5 s):
--     punto = LED encendido 1 tick  (0,5 s)
--     raya  = LED encendido 3 ticks (1,5 s)
--     pausa = LED apagado   1 tick  (0,5 s) despues de cada simbolo
-- =============================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity morse_fsm is
    port ( Clock, Reset                    : in  std_logic;
           Start, Tick, Simbolo, CntCero   : in  std_logic;
           LED, Carga, Desplaza            : out std_logic;
           Decrementa, Limpia, Ocupado     : out std_logic );
end entity;

architecture morse_fsm_arch of morse_fsm is

    -- Declaracion de los estados (tipo enumerado definido por el usuario)
    type State_Type is (sEspera,     -- espera que se presione KEY1
                        sCargar,     -- carga patron y longitud de la letra
                        sEvaluar,    -- decide: punto, raya o fin
                        sPunto,      -- LED encendido 1 tick
                        sRaya1,      -- LED encendido, tick 1 de 3
                        sRaya2,      -- LED encendido, tick 2 de 3
                        sRaya3,      -- LED encendido, tick 3 de 3
                        sPausa,      -- LED apagado 1 tick entre simbolos
                        sSiguiente,  -- desplaza registro y decrementa contador
                        sFin);       -- letra terminada, espera soltar KEY1
    signal current_state, next_state : State_Type;

begin

    -- -------------------------------------------------------------------------
    -- 1) MEMORIA DE ESTADO
    --    Registro de estado con reset asincrono activo en bajo.
    -- -------------------------------------------------------------------------
    STATE_MEMORY : process (Clock, Reset)
    begin
        if (Reset = '0') then
            current_state <= sEspera;
        elsif (Clock'event and Clock = '1') then
            current_state <= next_state;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- 2) LOGICA DE TRANSICION DE ESTADOS (estado siguiente)
    -- -------------------------------------------------------------------------
    NEXT_STATE_LOGIC : process (current_state, Start, Tick, Simbolo, CntCero)
    begin
        case (current_state) is

            when sEspera    => if (Start = '1') then
                                   next_state <= sCargar;
                               else
                                   next_state <= sEspera;
                               end if;

            when sCargar    => next_state <= sEvaluar;

            when sEvaluar   => if (CntCero = '1') then
                                   next_state <= sFin;      -- no quedan simbolos
                               elsif (Simbolo = '1') then
                                   next_state <= sRaya1;    -- siguiente es raya
                               else
                                   next_state <= sPunto;    -- siguiente es punto
                               end if;

            when sPunto     => if (Tick = '1') then
                                   next_state <= sPausa;
                               else
                                   next_state <= sPunto;
                               end if;

            when sRaya1     => if (Tick = '1') then
                                   next_state <= sRaya2;
                               else
                                   next_state <= sRaya1;
                               end if;

            when sRaya2     => if (Tick = '1') then
                                   next_state <= sRaya3;
                               else
                                   next_state <= sRaya2;
                               end if;

            when sRaya3     => if (Tick = '1') then
                                   next_state <= sPausa;
                               else
                                   next_state <= sRaya3;
                               end if;

            when sPausa     => if (Tick = '1') then
                                   next_state <= sSiguiente;
                               else
                                   next_state <= sPausa;
                               end if;

            when sSiguiente => next_state <= sEvaluar;

            when sFin       => if (Start = '0') then      -- espera soltar KEY1
                                   next_state <= sEspera;
                               else
                                   next_state <= sFin;
                               end if;

            when others     => next_state <= sEspera;
        end case;
    end process;

    -- -------------------------------------------------------------------------
    -- 3) LOGICA DE SALIDA (Moore: depende solo del estado actual)
    -- -------------------------------------------------------------------------
    OUTPUT_LOGIC : process (current_state)
    begin
        -- valores por defecto (evitan latches)
        LED        <= '0';
        Carga      <= '0';
        Desplaza   <= '0';
        Decrementa <= '0';
        Limpia     <= '0';
        Ocupado    <= '1';

        case (current_state) is
            when sEspera    => Limpia <= '1'; Ocupado <= '0';
            when sCargar    => Carga  <= '1'; Limpia  <= '1';
            when sEvaluar   => Limpia <= '1';
            when sPunto     => LED    <= '1';
            when sRaya1     => LED    <= '1';
            when sRaya2     => LED    <= '1';
            when sRaya3     => LED    <= '1';
            when sPausa     => LED    <= '0';
            when sSiguiente => Desplaza <= '1'; Decrementa <= '1';
            when sFin       => Ocupado <= '0';
            when others     => Ocupado <= '0';
        end case;
    end process;

end architecture;
