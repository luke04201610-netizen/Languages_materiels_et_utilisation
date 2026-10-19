# Partie 4.2 - processor with clock, reset and bus ports (data still inside)
# In the ModelSim transcript:  do C:/VHDL_polytech/partie4/q3_horloge/sim.do [program]
#   program: instr.txt by default, or instr2.txt, test_base.txt, test_rv32im.txt...
#   looked for in this folder, in C:/VHDL_polytech/programmes, then in C:/VHDL_polytech
#   The results must be the same as in q2_rv32im

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
  vlog -sv riscvproc.sv tb_riscvproc.sv

  # -onfinish stop: ebreak ($finish) stops the simulation without closing it
  vsim -voptargs=+acc -onfinish stop +prog=$progfile work.tb_riscvproc
  if {![batch_mode]} {
    add wave /tb_riscvproc/clock /tb_riscvproc/reset
    add wave -radix unsigned /tb_riscvproc/cpu/pc
    add wave -radix hexadecimal /tb_riscvproc/cpu/instr
    add wave -radix decimal /tb_riscvproc/cpu/regs
  }
  onbreak {resume}
  run -all

  # data word at address a: the data are in the memory of the processor
  proc mem_path {a} {
    return "/tb_riscvproc/cpu/memory\[$a\]"
  }
  echo "Program: $progfile"
  show_regs /tb_riscvproc/cpu/regs
  check_results /tb_riscvproc/cpu/regs $prog
  if {![batch_mode]} {wave zoom full}
}
