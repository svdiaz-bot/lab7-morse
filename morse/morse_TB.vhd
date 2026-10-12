-- =============================================================================
--  Archivo : morse_TB.vhd
--  Descripcion :
--     Testbench del sistema completo (entidad tope morse).
--     Para que la simulacion sea rapida se usa N_MEDIO_SEG = 4, es decir,
--     "medio segundo" = 4 ciclos de reloj (80 ns). En la tarjeta vale 25_000_000.
--
--     Pruebas:
--       1) Las 8 letras A..H: se presiona KEY1 y se decodifica LEDR0 midiendo
--          la duracion de cada pulso (1 tick = punto, 3 ticks = raya).
--          El resultado se compara con el codigo Morse esperado.
--       2) KEY1 sostenido mucho tiempo -> la letra se envia una sola vez.
--       3) Reset asincrono (KEY0) en medio de una transmision.
-- =============================================================================
library IEEE;
use IEEE.std_logic_1164.all;

entity morse_TB is
end entity;

architecture morse_TB_arch of morse_TB is

    -- Declaracion del componente (DUT)
    component morse
        generic ( N_MEDIO_SEG : positive := 25_000_000 );
        port ( CLOCK_50 : in  std_logic;
               KEY      : in  std_logic_vector(1 downto 0);
               SW       : in  std_logic_vector(2 downto 0);
               LEDR     : out std_logic_vector(9 downto 0) );
    end component;

    constant T     : time     := 20 ns;          -- 50 MHz
    constant N     : positive := 4;              -- ciclos por "medio segundo"
    constant PUNTO : time     := N * T;          -- 80 ns
    constant RAYA  : time     := 3 * N * T;      -- 240 ns

    signal CLOCK_50_TB : std_logic := '0';
    signal KEY_TB      : std_logic_vector(1 downto 0) := "11";
    signal SW_TB       : std_logic_vector(2 downto 0) := "000";
    signal LEDR_TB     : std_logic_vector(9 downto 0);
    signal fin_sim     : boolean := false;

    -- Codigo esperado de cada letra (rellenado con espacios)
    type tabla_morse is array (0 to 7) of string(1 to 4);
    constant ESPERADO : tabla_morse := (".-  ", "-...", "-.-.", "-.. ",
                                        ".   ", "..-.", "--. ", "....");
    constant LETRAS   : string(1 to 8) := "ABCDEFGH";

begin

    -- Instancia del DUT
    DUT1 : morse
        generic map ( N_MEDIO_SEG => N )
        port map ( CLOCK_50 => CLOCK_50_TB, KEY => KEY_TB,
                   SW => SW_TB, LEDR => LEDR_TB );

    -- Reloj de 50 MHz
    CLOCK_GEN : process
    begin
        if fin_sim then
            wait;
        end if;
        CLOCK_50_TB <= '0'; wait for T/2;
        CLOCK_50_TB <= '1'; wait for T/2;
    end process;

    STIMULUS : process
        variable recibido : string(1 to 4);
        variable nsim     : integer;
        variable t0       : time;
        variable dur      : time;
        variable errores  : integer := 0;
        variable pulsos   : integer;
    begin
        -- ---------------- Reset inicial (KEY0) ----------------
        KEY_TB <= "10";                      -- KEY0 presionado
        wait for 3*T;
        KEY_TB <= "11";
        wait for 3*T;

        -- ---------------- Prueba 1: letras A..H ----------------
        for L in 0 to 7 loop
            case L is
                when 0 => SW_TB <= "000";
                when 1 => SW_TB <= "001";
                when 2 => SW_TB <= "010";
                when 3 => SW_TB <= "011";
                when 4 => SW_TB <= "100";
                when 5 => SW_TB <= "101";
                when 6 => SW_TB <= "110";
                when others => SW_TB <= "111";
            end case;
            wait for 2*T;

            KEY_TB(1) <= '0';                          -- se presiona KEY1
            wait until LEDR_TB(9) = '1';               -- la FSM arranco
            wait for T;
            KEY_TB(1) <= '1';                          -- se suelta KEY1

            recibido := "    ";
            nsim := 0;
            loop
                if LEDR_TB(0) /= '1' then
                    wait until LEDR_TB(0) = '1' or LEDR_TB(9) = '0';
                end if;
                exit when LEDR_TB(9) = '0';            -- termino la letra
                t0 := now;
                wait until LEDR_TB(0) = '0';
                dur := now - t0;
                nsim := nsim + 1;
                if nsim > 4 then
                    report "ERROR: demasiados simbolos" severity error;
                    errores := errores + 1;
                    exit;
                end if;
                if dur = PUNTO then
                    recibido(nsim) := '.';
                elsif dur = RAYA then
                    recibido(nsim) := '-';
                else
                    recibido(nsim) := '?';
                    report "ERROR: pulso de duracion " & time'image(dur) severity error;
                end if;
            end loop;

            if recibido = ESPERADO(L) then
                report "OK    letra " & LETRAS(L+1) & " : " & recibido severity note;
            else
                report "ERROR letra " & LETRAS(L+1) & " : recibido " & recibido &
                       " esperado " & ESPERADO(L) severity error;
                errores := errores + 1;
            end if;
            wait for 4*T;
        end loop;

        -- ---------------- Prueba 2: KEY1 sostenido (letra E) ----------------
        SW_TB  <= "100";
        wait for 2*T;
        KEY_TB(1) <= '0';
        pulsos := 0;
        t0 := now;
        while now - t0 < 20 * PUNTO loop                 -- KEY1 presionado largo rato
            wait until LEDR_TB(0) = '1' for (20 * PUNTO - (now - t0));
            if LEDR_TB(0) = '1' then
                pulsos := pulsos + 1;
                wait until LEDR_TB(0) = '0';
            end if;
        end loop;
        if pulsos = 1 and LEDR_TB(9) = '0' then
            report "OK    KEY1 sostenido: la letra se envio una sola vez" severity note;
        else
            report "ERROR KEY1 sostenido: " & integer'image(pulsos) & " pulsos" severity error;
            errores := errores + 1;
        end if;
        KEY_TB(1) <= '1';
        wait for 6*T;

        -- ---------------- Prueba 3: reset asincrono durante H ----------------
        SW_TB  <= "111";
        wait for 2*T;
        KEY_TB(1) <= '0';
        wait until LEDR_TB(9) = '1';
        KEY_TB(1) <= '1';
        wait until LEDR_TB(0) = '1';
        wait until LEDR_TB(0) = '0';
        wait until LEDR_TB(0) = '1';                     -- segundo punto encendido
        wait for T/4;                                    -- entre flancos de reloj
        KEY_TB(0) <= '0';                                -- KEY0 = reset
        wait for 1 ns;
        if LEDR_TB(0) = '0' and LEDR_TB(9) = '0' then
            report "OK    reset asincrono apaga el LED inmediatamente" severity note;
        else
            report "ERROR reset asincrono" severity error;
            errores := errores + 1;
        end if;
        wait for 3*T;
        KEY_TB(0) <= '1';
        wait for 10*T;

        -- ---------------- Resultado ----------------
        if errores = 0 then
            report "==== morse_TB: TODAS LAS PRUEBAS PASARON ====" severity note;
        else
            report "==== morse_TB: " & integer'image(errores) & " ERRORES ====" severity failure;
        end if;
        fin_sim <= true;
        wait;
    end process;

end architecture;
