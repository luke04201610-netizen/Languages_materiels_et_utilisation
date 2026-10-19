# Q3 - model with unsigned (Q2), short scenario (architecture Bench)
# In the ModelSim transcript:  do C:/VHDL_polytech/partie2/q2_unsigned/sim_bench.do
# The waveform must be the same as the one of q1_original/sim_bench.do

# end the current simulation (ModelSim refuses cd during a simulation),
# then work in the folder of this script
quit -sim
cd [file dirname [status file]]

if {[file exists work]} {vdel -lib work -all}
vlib work
vcom -93 sync_ram.vhd ram_tb.vhd

vsim -voptargs=+acc work.ram_tb(bench)
if {![batch_mode]} {
  add wave -radix unsigned /ram_tb/clock /ram_tb/we /ram_tb/address /ram_tb/datain /ram_tb/dataout
  add wave -divider "inside the RAM"
  add wave -radix unsigned /ram_tb/UUT/read_address {/ram_tb/UUT/ram(1)} {/ram_tb/UUT/ram(2)}
}
run -all
if {![batch_mode]} {wave zoom full}
