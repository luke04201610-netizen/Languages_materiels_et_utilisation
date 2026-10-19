# Partie 3 Q4 - generic quadram, write then read back all the addresses (architecture Bench2),
# for several configurations: the same code is simulated with different generics.
# In the ModelSim transcript:  do C:/VHDL_polytech/partie3/q4_generique/sim_bench2.do
# Each run must print "Bench2 OK"; the last one (figure 2) stays in the wave window.

# end the current simulation (ModelSim refuses cd during a simulation),
# then work in the folder of this script
quit -sim
cd [file dirname [status file]]

if {[file exists work]} {vdel -lib work -all}
vlib work
# reused block: the RAM of partie 2 (Q5)
vcom -93 ../../partie2/q5_cs/sync_ram.vhd util_pkg.vhd decoder.vhd quadram.vhd quadram_tb.vhd

# {N Nbits_addr Nbits_data}: 2 RAMs, 8 RAMs, 3 RAMs (not a power of 2),
# 4 x 1024 x 32 bits (figure 4, memory of the processor), 4 x 256 x 8 bits (figure 2)
foreach {n na nd} {2 4 8  8 4 16  3 4 8  4 10 32  4 8 8} {
  quit -sim
  vsim -voptargs=+acc -gN=$n -gNbits_addr=$na -gNbits_data=$nd work.quadram_tb(bench2)
  if {![batch_mode]} {
    add wave /quadram_tb/clock /quadram_tb/we
    add wave -radix hexadecimal /quadram_tb/address /quadram_tb/datain /quadram_tb/dataout
    add wave -radix binary /quadram_tb/UUT/cs
    add wave /quadram_tb/ok
  }
  run -all
}
if {![batch_mode]} {wave zoom full}
