# Partie 5 - complete system: RISC-V processor (Verilog) + quadram (VHDL)
# In the ModelSim transcript:  do C:/VHDL_polytech/partie5/sim.do [program]
#   program: instr.txt by default, or instr2.txt (validation by the teacher),
#   test_memoire.txt, test_base.txt, test_rv32im.txt... looked for in this folder,
#   in C:/VHDL_polytech/programmes, then in C:/VHDL_polytech
#   The results are compared with the expected values of programmes/verif.tcl

# end the current simulation (ModelSim refuses cd during a simulation),
# then work in the folder of this script
quit -sim
cd [file dirname [status file]]
source ../programmes/verif.tcl

if {$argc >= 1} {set prog $1} else {set prog instr.txt}
set progfile [find_prog $prog {. ../programmes ..}]

if {$progfile eq ""} {
  echo "Program $prog not found: put it in C:/VHDL_polytech/programmes"
} else {
  if {[file exists work]} {vdel -lib work -all}
  vlib work
  # processor (Verilog), blocks reused from partie 2 and 3 (VHDL), then the system
  vlog -sv riscvproc.sv
  vcom -93 ../partie2/q5_cs/sync_ram.vhd ../partie3/q4_generique/util_pkg.vhd \
           ../partie3/q4_generique/decoder.vhd ../partie3/q4_generique/quadram.vhd \
           systeme.vhd systeme_tb.vhd

  # -onfinish stop: ebreak ($finish) stops the simulation without closing it
  vsim -voptargs=+acc -onfinish stop +prog=$progfile work.systeme_tb(bench)
  if {![batch_mode]} {
    add wave /systeme_tb/clock /systeme_tb/reset
    add wave -radix unsigned /systeme_tb/UUT/CPU/pc
    add wave -radix hexadecimal /systeme_tb/UUT/CPU/instr
    add wave -divider "bus processor - quadram"
    add wave /systeme_tb/UUT/we
    add wave -radix unsigned /systeme_tb/UUT/address
    add wave -radix decimal /systeme_tb/UUT/dataToWrite /systeme_tb/UUT/dataToRead
    add wave -radix binary /systeme_tb/UUT/MEM/cs
    add wave -divider "registers"
    add wave -radix decimal /systeme_tb/UUT/CPU/regs
  }
  onbreak {resume}
  run -all

  # data word at address a of the quadram: RAM a / 1024, word a mod 1024
  proc mem_path {a} {
    return "/systeme_tb/UUT/MEM/RAMS([expr {$a / 1024}])/RAM/ram([expr {$a % 1024}])"
  }
  echo "Program: $progfile"
  show_regs /systeme_tb/UUT/CPU/regs
  check_results /systeme_tb/UUT/CPU/regs $prog
  if {![batch_mode]} {wave zoom full}
}
