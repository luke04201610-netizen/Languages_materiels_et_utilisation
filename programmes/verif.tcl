# Helpers for the do scripts of partie 4 and partie 5 (loaded with "source"):
# find the program file, then print and check the results once the
# processor has stopped on ebreak.

# Expected results of the test programs:
#   xN = value of register N, mA = data word at address A (signed decimal)
set expected(instr2.txt)       {x1 1  x2 6  m65 6}
set expected(test_base.txt)    {x0 0  x1 -7  x2 100  x3 107  x4 -16  x5 -1  x6 3
                                x7 800  x8 536870911  x9 107  x10 -7  x11 0
                                m104 107  m96 -7}
set expected(test_rv32im.txt)  {x1 -7  x2 2  x3 -14  x4 -3  x5 -1  x6 2147483644
                                x7 -1  x8 -1  x9 1  x10 1  x11 -2147483648  x12 -1
                                x13 31  x14 -2147483648  x15 0  x16 -1}
set expected(test_memoire.txt) {x20 11  x21 22  x22 33  x23 44  x24 110  x25 44  x26 110
                                m5 11  m1029 22  m2053 33  m3077 44  m1023 110}

# Path of the program file: looked for in each folder of dirs, "" if not found
proc find_prog {name dirs} {
  foreach d $dirs {
    if {[file exists $d/$name]} {return $d/$name}
  }
  return ""
}

# Prints the registers that are not 0 (regs: path of the register file)
proc show_regs {regs} {
  echo "Registers not equal to 0:"
  for {set i 1} {$i < 32} {incr i} {
    set v [examine -radix decimal "$regs\[$i\]"]
    if {$v ne "0"} {
      echo [format "  x%-2d = %11s   0x%s" $i $v [examine -radix hex "$regs\[$i\]"]]
    }
  }
}

# Compares the results of program prog with its expected values, if any.
# regs: path of the register file; the data words are read with the proc
# mem_path, defined by the do script (internal memory or quadram).
proc check_results {regs prog} {
  global expected
  if {![info exists expected($prog)]} {
    echo "No expected values for $prog: check the registers above"
    return
  }
  set errors 0
  foreach {key value} $expected($prog) {
    set n [string range $key 1 end]
    if {[string index $key 0] eq "x"} {
      set got [examine -radix decimal "$regs\[$n\]"]
    } else {
      set got [examine -radix decimal [mem_path $n]]
    }
    if {$got eq $value} {
      echo [format "  OK     %-6s = %s" $key $got]
    } else {
      echo [format "  ERROR  %-6s = %s, expected %s" $key $got $value]
      incr errors
    }
  }
  if {$errors == 0} {
    echo "TEST $prog: OK"
  } else {
    echo "TEST $prog: FAILED, $errors error(s)"
  }
}
