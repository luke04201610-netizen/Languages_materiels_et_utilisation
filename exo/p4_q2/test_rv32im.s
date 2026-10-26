# M extension (partie 4.1.2): the 8 instructions, with the special cases
# of the specification (division by zero, overflow)
addi   x1, x0, -7      # x1 = -7
addi   x2, x0, 2       # x2 = 2
mul    x3, x1, x2      # x3 = -14
div    x4, x1, x2      # x4 = -3          (rounded towards 0)
rem    x5, x1, x2      # x5 = -1          (sign of the dividend)
divu   x6, x1, x2      # x6 = 0x7FFFFFFC = 2147483644
div    x7, x1, x0      # x7 = -1          (division by zero)
mulh   x8, x1, x2      # x8 = -1          (high word of -14)
mulhu  x9, x1, x2      # x9 = 1           (0xFFFFFFF9 * 2 = 0x1_FFFFFFF2)
remu   x10, x1, x2     # x10 = 1
mulhsu x16, x1, x2     # x16 = -1         (high word of -14)
addi   x11, x0, 1
addi   x13, x0, 31
sll    x11, x11, x13   # x11 = 0x80000000 = -2^31
addi   x12, x0, -1     # x12 = -1
div    x14, x11, x12   # x14 = -2^31      (overflow)
rem    x15, x11, x12   # x15 = 0          (overflow)
ebreak
