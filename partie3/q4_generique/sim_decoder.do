# Partie 3 Q4 - generic decoder tested alone, for 1 to 4 inputs
# In the ModelSim transcript:  do C:/VHDL_polytech/partie3/q4_generique/sim_decoder.do
# Each run must print "Decoder OK"; the last one (2 -> 4) stays in the wave window.

# end the current simulation (ModelSim refuses cd during a simulation),
# then work in the folder of this script
quit -sim
cd [file dirname [status file]]

if {[file exists work]} {vdel -lib work -all}
vlib work
vcom -93 decoder.vhd decoder_tb.vhd

foreach nb {1 3 4 2} {
  quit -sim
  vsim -voptargs=+acc -gNbits_in=$nb work.decoder_tb(bench)
  if {![batch_mode]} {
    add wave -radix unsigned /decoder_tb/sel
    add wave -radix binary /decoder_tb/cs
  }
  run -all
}
if {![batch_mode]} {wave zoom full}
