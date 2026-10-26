# Base instructions of the processor, and the fixes of partie 4.1.2:
# negative immediates, load/store address = rs1 + offset, x0 always 0
addi x1, x0, -7        # x1 = -7         (negative immediate)
addi x2, x0, 100       # x2 = 100
sub  x3, x2, x1        # x3 = 107
andi x4, x1, -16       # x4 = -16        (0xFFFFFFF0)
ori  x5, x0, -1        # x5 = -1         (0xFFFFFFFF)
addi x6, x0, 3         # x6 = 3
sll  x7, x2, x6        # x7 = 800
srl  x8, x5, x6        # x8 = 0x1FFFFFFF = 536870911
sw   x3, 4(x2)         # word 104 = 107
sw   x1, -4(x2)        # word 96 = -7    (negative offset)
lw   x9, 4(x2)         # x9 = 107
lw   x10, -4(x2)       # x10 = -7
addi x0, x0, 5         # x0 stays 0
add  x11, x0, x0       # x11 = 0
ebreak
