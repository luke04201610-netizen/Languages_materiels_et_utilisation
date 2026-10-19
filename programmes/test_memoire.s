# Data in the 4 RAMs of the quadram (partie 5): the same offset (5) in each RAM,
# read back; a negative offset; the boundary between RAM 0 and RAM 1;
# a lw just after a sw at the same address
addi x5, x0, 1024      # x5 = 1024: first word of RAM 1
add  x6, x5, x5        # x6 = 2048: first word of RAM 2
add  x7, x6, x5        # x7 = 3072: first word of RAM 3
addi x10, x0, 11
addi x11, x0, 22
addi x12, x0, 33
addi x13, x0, 44
sw   x10, 5(x0)        # word 5    (RAM 0) = 11
sw   x11, 5(x5)        # word 1029 (RAM 1) = 22
sw   x12, 5(x6)        # word 2053 (RAM 2) = 33
sw   x13, 5(x7)        # word 3077 (RAM 3) = 44
lw   x20, 5(x0)        # x20 = 11
lw   x21, 5(x5)        # x21 = 22
lw   x22, 5(x6)        # x22 = 33
lw   x23, 5(x7)        # x23 = 44
add  x24, x20, x21     # x24 = 33
add  x24, x24, x22     # x24 = 66
add  x24, x24, x23     # x24 = 110
addi x8, x7, 10        # x8 = 3082
lw   x25, -5(x8)       # x25 = word 3077 = 44  (negative offset)
sw   x24, -1(x5)       # word 1023 (last word of RAM 0) = 110
lw   x26, 1023(x0)     # x26 = 110
ebreak
