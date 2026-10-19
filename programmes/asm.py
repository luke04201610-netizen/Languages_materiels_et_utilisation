"""Mini assembler for the instructions of the project processor.

Usage:  python asm.py test_base.s > test_base.txt
The output has the format read by $readmemh (same as instr2.txt): one 32-bit
hexadecimal word per instruction, with the assembly code as a comment.

Supported instructions (those of the processor, partie 4):
  add sub sll srl  mul mulh mulhsu mulhu div divu rem remu   rd, rs1, rs2
  addi andi ori                                              rd, rs1, imm
  lw rd, imm(rs1)    sw rs2, imm(rs1)    ebreak
Comments start with '#'. Immediates: -2048 to 2047, decimal or 0x...
"""
import re
import sys

R = {  # name: (funct3, funct7)
    "add": (0, 0x00), "sub": (0, 0x20), "sll": (1, 0x00), "srl": (5, 0x00),
    "mul": (0, 0x01), "mulh": (1, 0x01), "mulhsu": (2, 0x01), "mulhu": (3, 0x01),
    "div": (4, 0x01), "divu": (5, 0x01), "rem": (6, 0x01), "remu": (7, 0x01),
}
I = {"addi": 0, "andi": 7, "ori": 6}  # name: funct3


def reg(s):
    m = re.fullmatch(r"x(\d+)", s.strip())
    if not m or int(m.group(1)) > 31:
        raise ValueError("bad register: " + s)
    return int(m.group(1))


def imm12(s):
    v = int(s, 0)
    if not -2048 <= v <= 2047:
        raise ValueError("immediate out of range: " + s)
    return v & 0xFFF


def encode(line):
    op, _, args = line.partition(" ")
    a = [x.strip() for x in args.split(",")] if args.strip() else []
    if op in R:    # R-type: funct7 | rs2 | rs1 | funct3 | rd | opcode
        f3, f7 = R[op]
        return f7 << 25 | reg(a[2]) << 20 | reg(a[1]) << 15 | f3 << 12 | reg(a[0]) << 7 | 0x33
    if op in I:    # I-type: imm[11:0] | rs1 | funct3 | rd | opcode
        return imm12(a[2]) << 20 | reg(a[1]) << 15 | I[op] << 12 | reg(a[0]) << 7 | 0x13
    if op in ("lw", "sw"):
        m = re.fullmatch(r"(-?\w+)\((x\d+)\)", a[1].replace(" ", ""))
        if not m:
            raise ValueError("expected imm(rs1): " + line)
        imm, base = imm12(m.group(1)), reg(m.group(2))
        if op == "lw":  # I-type
            return imm << 20 | base << 15 | 2 << 12 | reg(a[0]) << 7 | 0x03
        # S-type: imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
        return (imm >> 5) << 25 | reg(a[0]) << 20 | base << 15 | 2 << 12 | (imm & 0x1F) << 7 | 0x23
    if op == "ebreak":
        return 0x00100073
    raise ValueError("unknown instruction: " + line)


def main(path):
    out = ["// instructions at address 0x0", "@0"]
    for raw in open(path, encoding="utf-8"):
        line = raw.split("#")[0].strip()
        if line:
            out.append("%08x // %s" % (encode(line), re.sub(r"\s+", " ", line)))
    print("\n".join(out))


if __name__ == "__main__":
    main(sys.argv[1])
