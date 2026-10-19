# Partie 4.1.2 - processor fixed (immediates, load/store address, x0) and RV32IM
# In the ModelSim transcript:  do C:/VHDL_polytech/partie4/q2_rv32im/sim.do [program]
#   program: instr.txt by default, or instr2.txt, test_base.txt, test_rv32im.txt...
#   looked for in this folder, in C:/VHDL_polytech/programmes, then in C:/VHDL_polytech
#   The results are compared with the expected values of programmes/verif.tcl

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

  # data word at address a: the data are in the memory of the processor
  proc mem_path {a} {
    return "/system/memory\[$a\]"
  }
  echo "Program: $progfile"
  show_regs /system/regs
  check_results /system/regs $prog
  if {![batch_mode]} {wave zoom full}
}
