# Partie 3 Q3 - quadram made of 4 sync_ram, same offset written in each RAM (architecture Bench)
# In the ModelSim transcript:  do C:/VHDL_polytech/partie3/q2_quadram/sim_bench.do

# end the current simulation (ModelSim refuses cd during a simulation),
# then work in the folder of this script
quit -sim
cd [file dirname [status file]]

if {[file exists work]} {vdel -lib work -all}
vlib work
# reused blocks: the RAM of partie 2 (Q5) and the decoder of Q1
vcom -93 ../../partie2/q5_cs/sync_ram.vhd ../q1_decodeur/decoder.vhd quadram.vhd quadram_tb.vhd

vsim -voptargs=+acc work.quadram_tb(bench)
if {![batch_mode]} {
  add wave /quadram_tb/clock /quadram_tb/we
  add wave -radix hexadecimal /quadram_tb/address /quadram_tb/datain /quadram_tb/dataout
  add wave -divider "inside the quadram"
  add wave -radix binary /quadram_tb/UUT/cs
  add wave -radix hexadecimal {/quadram_tb/UUT/RAM0/ram(5)} {/quadram_tb/UUT/RAM1/ram(5)} {/quadram_tb/UUT/RAM2/ram(5)} {/quadram_tb/UUT/RAM3/ram(5)}
}
run -all
if {![batch_mode]} {wave zoom full}
