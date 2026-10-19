# Partie 3 Q4 - generic quadram (N = 4 by default), same offset written in each RAM (architecture Bench)
# In the ModelSim transcript:  do C:/VHDL_polytech/partie3/q4_generique/sim_bench.do

# end the current simulation (ModelSim refuses cd during a simulation),
# then work in the folder of this script
quit -sim
cd [file dirname [status file]]

if {[file exists work]} {vdel -lib work -all}
vlib work
# reused block: the RAM of partie 2 (Q5)
vcom -93 ../../partie2/q5_cs/sync_ram.vhd util_pkg.vhd decoder.vhd quadram.vhd quadram_tb.vhd

vsim -voptargs=+acc work.quadram_tb(bench)
if {![batch_mode]} {
  add wave /quadram_tb/clock /quadram_tb/we
  add wave -radix hexadecimal /quadram_tb/address /quadram_tb/datain /quadram_tb/dataout
  add wave -divider "inside the quadram"
  add wave -radix binary /quadram_tb/UUT/cs
  for {set i 0} {$i < 4} {incr i} {
    add wave -radix hexadecimal "/quadram_tb/UUT/RAMS($i)/RAM/ram(5)"
  }
}
run -all
if {![batch_mode]} {wave zoom full}
