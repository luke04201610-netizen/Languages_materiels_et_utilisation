# Q3 - model with unsigned (Q2), write then read back all the addresses (architecture Bench2)
# In the ModelSim transcript:  do C:/VHDL_polytech/partie2/q2_unsigned/sim_bench2.do
# ok must stay TRUE, as with q1_original/sim_bench2.do

# end the current simulation (ModelSim refuses cd during a simulation),
# then work in the folder of this script
quit -sim
cd [file dirname [status file]]

if {[file exists work]} {vdel -lib work -all}
vlib work
vcom -93 sync_ram.vhd ram_tb.vhd

vsim -voptargs=+acc work.ram_tb(bench2)
if {![batch_mode]} {
  add wave -radix unsigned /ram_tb/clock /ram_tb/we /ram_tb/address /ram_tb/datain /ram_tb/dataout /ram_tb/ok
}
run -all
echo "Bench2 finished at $now ns: ok = [examine /ram_tb/ok]"
if {![batch_mode]} {wave zoom full}
