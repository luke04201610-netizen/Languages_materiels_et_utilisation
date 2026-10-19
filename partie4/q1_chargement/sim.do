# Partie 4.1 - processor as provided, with the program loading ($readmemh)
# In the ModelSim transcript:  do C:/VHDL_polytech/partie4/q1_chargement/sim.do [program]
#   program: instr.txt by default (first test program, from Madoc), or instr2.txt,
#   test_base.txt... looked for in this folder, in C:/VHDL_polytech/programmes,
#   then in C:/VHDL_polytech

# end the current simulation (ModelSim refuses cd during a simulation),
# then work in the folder of this script
quit -sim
cd [file dirname [status file]]
source ../../programmes/verif.tcl

if {$argc >= 1} {set prog $1} else {set prog instr.txt}
set progfile [find_prog $prog {. ../../programmes ../..}]

if {$progfile eq ""} {
  echo "Program $prog not found: put it in C:/VHDL_polytech/programmes"
} else {
  if {[file exists work]} {vdel -lib work -all}
  vlib work
  vlog -sv riscvproc.sv

  # -onfinish stop: ebreak ($finish) stops the simulation without closing it
  vsim -voptargs=+acc -onfinish stop +prog=$progfile work.system
  if {![batch_mode]} {
    add wave -radix unsigned /system/pc
    add wave -radix hexadecimal /system/instr
    add wave -radix decimal /system/regs
  }
  onbreak {resume}
  run -all

  echo "Program: $progfile"
  show_regs /system/regs
  if {$prog eq "instr2.txt"} {
    # sw x2, 64(x1) should write 6 in the word 65, without touching the program
    echo "memory\[65\] = [examine -radix hex /system/memory\[65\]]   (00000006 expected)"
    echo "memory\[0\]  = [examine -radix hex /system/memory\[0\]]   (first instruction 00200093 expected)"
  }
  if {![batch_mode]} {wave zoom full}
}
