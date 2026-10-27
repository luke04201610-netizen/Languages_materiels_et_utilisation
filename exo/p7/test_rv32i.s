# Part 7: self-checking test of the RV32I instructions not used by programme.c.
# At the end a0 = 0 if every check passes, otherwise a0 = number of the failing check.
# python asm_rv32.py test_rv32i.s > test_rv32i.txt

_start:
    li    a0, 1                 # check 1: lui
    lui   t0, 0x12345
    li    t1, 0x12345000
    bne   t0, t1, fail
    li    a0, 2                 # check 2: auipc gives the address of the instruction
    jal   t1, next2             # t1 = address of next2
next2:
    auipc t2, 0
    bne   t1, t2, fail
    li    a0, 3                 # check 3: slt, sltu, slti, sltiu
    li    t0, -5
    li    t1, 3
    li    t3, 1
    slt   t2, t0, t1            # -5 < 3 (signed): 1
    bne   t2, t3, fail
    sltu  t2, t0, t1            # 0xFFFFFFFB < 3 (unsigned): 0
    bne   t2, zero, fail
    slti  t2, t0, -4            # -5 < -4: 1
    bne   t2, t3, fail
    sltiu t2, t1, -1            # 3 < 0xFFFFFFFF: 1
    bne   t2, t3, fail
    li    a0, 4                 # check 4: xor, or, and
    li    t0, 0xF0F0
    xori  t1, t0, 0x0FF         # 0xF00F
    li    t2, 0xF00F
    bne   t1, t2, fail
    li    t3, 0x0FF0
    or    t1, t0, t3            # 0xFFF0
    li    t2, 0xFFF0
    bne   t1, t2, fail
    and   t1, t0, t3            # 0x00F0
    li    t2, 0x00F0
    bne   t1, t2, fail
    andi  t1, t0, 0x0F0         # 0x00F0
    bne   t1, t2, fail
    li    a0, 5                 # check 5: shifts
    li    t0, -16               # 0xFFFFFFF0
    srai  t1, t0, 2             # -4
    li    t2, -4
    bne   t1, t2, fail
    srli  t1, t0, 28            # 15
    li    t2, 15
    bne   t1, t2, fail
    li    t3, 4
    sra   t1, t0, t3            # -1
    li    t2, -1
    bne   t1, t2, fail
    srl   t1, t0, t3            # 0x0FFFFFFF
    li    t2, 0x0FFFFFFF
    bne   t1, t2, fail
    sll   t1, t0, t3            # 0xFFFFFF00
    li    t2, -256
    bne   t1, t2, fail
    li    a0, 6                 # check 6: signed and unsigned branches
    li    t0, -1
    li    t1, 1
    blt   t1, t0, fail          # 1 < -1 (signed): not taken
    bltu  t0, t1, fail          # 0xFFFFFFFF < 1 (unsigned): not taken
    bge   t1, t0, ok6           # 1 >= -1 (signed): taken
    j     fail
ok6:
    bgeu  t0, t1, ok6b          # 0xFFFFFFFF >= 1 (unsigned): taken
    j     fail
ok6b:
    beq   t0, t0, ok6c          # taken
    j     fail
ok6c:
    li    a0, 7                 # check 7: call (auipc + jalr) and ret
    li    a1, 20
    call  double                # a1 = 40
    li    t0, 40
    bne   a1, t0, fail
    li    a0, 8                 # check 8: byte addresses, two words 4 bytes apart
    li    t0, 0x100
    li    t1, 111
    li    t2, 222
    sw    t1, 0(t0)
    sw    t2, 4(t0)
    lw    t3, 0(t0)
    bne   t3, t1, fail
    lw    t3, 4(t0)
    bne   t3, t2, fail
    li    a0, 0                 # every check passed
fail:
    ebreak

double:
    add   a1, a1, a1
    ret
