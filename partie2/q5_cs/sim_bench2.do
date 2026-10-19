# Q5 - generic RAM with chip select, write then read back all the addresses,
# then chip select tests (architecture Bench2), for several sizes of RAM.
# In the ModelSim transcript:  do C:/VHDL_polytech/partie2/q5_cs/sim_bench2.do
# Each run must print "Bench2 OK"; the last one (default sizes) stays in the wave window.

# end the current simulation (ModelSim refuses cd during a simulation),
# then work in the folder of this script
quit -sim
cd [file dirname [status file]]

if {[file exists work]} {vdel -lib work -all}
vlib work
vcom -93 sync_ram.vhd ram_tb.vhd

# pairs {Nbits_addr Nbits_data}: 16 x 16 bits, 1024 x 32 bits (word of the processor), 1024 x 8 bits
foreach {na nd} {4 16  10 32  10 8} {
  quit -sim
  vsim -voptargs=+acc -gNbits_addr=$na -gNbits_data=$nd work.ram_tb(bench2)
  if {![batch_mode]} {
    add wave -radix unsigned /ram_tb/clock /ram_tb/cs /ram_tb/we /ram_tb/address /ram_tb/datain /ram_tb/dataout /ram_tb/ok
  }
  run -all
}
if {![batch_mode]} {wave zoom full}
