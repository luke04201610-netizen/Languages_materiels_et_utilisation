# Partie 3 Q1 - address decoder 2 -> 4, tested alone
# In the ModelSim transcript:  do C:/VHDL_polytech/partie3/q1_decodeur/sim.do

# end the current simulation (ModelSim refuses cd during a simulation),
# then work in the folder of this script
quit -sim
cd [file dirname [status file]]

if {[file exists work]} {vdel -lib work -all}
vlib work
vcom -93 decoder.vhd decoder_tb.vhd

vsim -voptargs=+acc work.decoder_tb(bench)
if {![batch_mode]} {
  add wave -radix unsigned /decoder_tb/sel
  add wave -radix binary /decoder_tb/cs
}
run -all
if {![batch_mode]} {wave zoom full}
