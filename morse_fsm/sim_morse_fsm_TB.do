# =============================================================================
#  Script ModelSim / Questa - testbench de la FSM aislada (morse_fsm_TB)
#  Uso: en la consola de ModelSim, ubicado en la carpeta testbench/:
#        do sim_morse_fsm_TB.do
# =============================================================================
vlib work
vcom -2008 ../src/morse_fsm.vhd
vcom -2008 morse_fsm_TB.vhd

vsim -voptargs=+acc work.morse_fsm_TB

add wave -divider "Entradas"
add wave -label Clock   sim:/morse_fsm_TB/Clock_TB
add wave -label Reset   sim:/morse_fsm_TB/Reset_TB
add wave -label Start   sim:/morse_fsm_TB/Start_TB
add wave -label Tick    sim:/morse_fsm_TB/Tick_TB
add wave -label Simbolo sim:/morse_fsm_TB/Simbolo_TB
add wave -label CntCero sim:/morse_fsm_TB/CntCero_TB
add wave -divider "Estado"
add wave -label estado  sim:/morse_fsm_TB/DUT1/current_state
add wave -divider "Salidas"
add wave -label LED        sim:/morse_fsm_TB/LED_TB
add wave -label Carga      sim:/morse_fsm_TB/Carga_TB
add wave -label Desplaza   sim:/morse_fsm_TB/Desplaza_TB
add wave -label Decrementa sim:/morse_fsm_TB/Decrementa_TB
add wave -label Limpia     sim:/morse_fsm_TB/Limpia_TB
add wave -label Ocupado    sim:/morse_fsm_TB/Ocupado_TB

run -all
wave zoom full
