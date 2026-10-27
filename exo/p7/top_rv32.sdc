# 50 MHz board clock
create_clock -name sys_clk -period 20.000 [get_ports {sys_clk}]

# system clock: bit 3 of the divider, 50 MHz / 16 = 3.125 MHz (DIV_LOG2 = 4 in top_rv32.vhd)
create_generated_clock -name clock -source [get_ports {sys_clk}] -divide_by 16 [get_registers {div[3]}]

derive_clock_uncertainty

# buttons, keys, LEDs and display are slow and asynchronous
set_false_path -from [get_ports {sys_rst_n key[*]}]
set_false_path -to [get_ports {led[*] sel[*] seg_led[*]}]
