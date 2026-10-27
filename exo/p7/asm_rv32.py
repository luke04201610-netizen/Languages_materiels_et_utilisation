"""Assembler and linker for the part 7 processor (RV32I + RV32M, byte addresses).

Usage:  python asm_rv32.py crt0.s programme.s > programme.txt
The files are placed one after the other from address 0 (crt0.s first, so that the
processor starts with it). The output has the format read by $readmemh: one 32-bit
hexadecimal word per instruction, with the assembly code as a comment.

It reads the assembly produced by gcc on godbolt.org: ABI register names (sp, a0...),
labels, directives (ignored) and the usual pseudo-instructions (li, mv, j, jr, ret,
call, ble, bgt, beqz, bnez...). 'call' is resolved like the linker does it, with an
auipc + jalr pair.
"""
import re
import sys

ABI = {"zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4, "t0": 5, "t1": 6, "t2": 7,
       "s0": 8, "fp": 8, "s1": 9, "t3": 28, "t4": 29, "t5": 30, "t6": 31}
ABI.update({"a%d" % i: 10 + i for i in range(8)})
ABI.update({"s%d" % i: 16 + i for i in range(2, 12)})

R = {  # name: (funct3, funct7)
    "add": (0, 0x00), "sub": (0, 0x20), "sll": (1, 0x00), "slt": (2, 0x00),
    "sltu": (3, 0x00), "xor": (4, 0x00), "srl": (5, 0x00), "sra": (5, 0x20),
    "or": (6, 0x00), "and": (7, 0x00),
    "mul": (0, 0x01), "mulh": (1, 0x01), "mulhsu": (2, 0x01), "mulhu": (3, 0x01),
    "div": (4, 0x01), "divu": (5, 0x01), "rem": (6, 0x01), "remu": (7, 0x01),
}
I_ALU = {"addi": 0, "slti": 2, "sltiu": 3, "xori": 4, "ori": 6, "andi": 7}
SHIFT = {"slli": (1, 0x00), "srli": (5, 0x00), "srai": (5, 0x20)}
LOAD = {"lb": 0, "lh": 1, "lw": 2, "lbu": 4, "lhu": 5}
STORE = {"sb": 0, "sh": 1, "sw": 2}
BRANCH = {"beq": 0, "bne": 1, "blt": 4, "bge": 5, "bltu": 6, "bgeu": 7}
# pseudo-branches: name -> (real branch, swap the operands)
BRANCH_SWAP = {"bgt": ("blt", True), "ble": ("bge", True),
               "bgtu": ("bltu", True), "bleu": ("bgeu", True)}
BRANCH_ZERO = {"beqz": ("beq", False), "bnez": ("bne", False), "bltz": ("blt", False),
               "bgez": ("bge", False), "blez": ("bge", True), "bgtz": ("blt", True)}


def reg(s):
    s = s.strip()
    if s in ABI:
        return ABI[s]
    m = re.fullmatch(r"x(\d+)", s)
    if m and int(m.group(1)) < 32:
        return int(m.group(1))
    raise ValueError("bad register: " + s)


def num(s):
    return int(s.strip(), 0)


def check(v, bits, name):
    if not -(1 << (bits - 1)) <= v < (1 << (bits - 1)):
        raise ValueError("%s out of range: %d" % (name, v))
    return v & ((1 << bits) - 1)


def r_type(f7, rs2, rs1, f3, rd, op):
    return f7 << 25 | rs2 << 20 | rs1 << 15 | f3 << 12 | rd << 7 | op


def i_type(imm, rs1, f3, rd, op):
    return check(imm, 12, "immediate") << 20 | rs1 << 15 | f3 << 12 | rd << 7 | op


def s_type(imm, rs2, rs1, f3):
    imm = check(imm, 12, "offset")
    return (imm >> 5) << 25 | rs2 << 20 | rs1 << 15 | f3 << 12 | (imm & 0x1F) << 7 | 0x23


def b_type(off, rs2, rs1, f3):
    o = check(off, 13, "branch offset")
    return ((o >> 12) & 1) << 31 | ((o >> 5) & 0x3F) << 25 | rs2 << 20 | rs1 << 15 \
        | f3 << 12 | ((o >> 1) & 0xF) << 8 | ((o >> 11) & 1) << 7 | 0x63


def j_type(off, rd):
    o = check(off, 21, "jump offset")
    return ((o >> 20) & 1) << 31 | ((o >> 1) & 0x3FF) << 21 | ((o >> 11) & 1) << 20 \
        | ((o >> 12) & 0xFF) << 12 | rd << 7 | 0x6F


def u_type(imm20, rd, op):
    return (imm20 & 0xFFFFF) << 12 | rd << 7 | op


def hi_lo(value):
    """Split a 32-bit value for lui/auipc + addi/jalr (the low part is signed)."""
    lo = ((value & 0xFFF) ^ 0x800) - 0x800
    return ((value - lo) >> 12) & 0xFFFFF, lo


def mem_operand(s):
    m = re.fullmatch(r"(-?\w*)\((\w+)\)", s.replace(" ", ""))
    if not m:
        raise ValueError("expected offset(register): " + s)
    return num(m.group(1) or "0"), reg(m.group(2))


def size(op, args):
    """Number of 32-bit words of an instruction (pass 1)."""
    if op == "call":
        return 2
    if op == "li":
        v = num(args[1])
        return 1 if -2048 <= v < 2048 else (1 if hi_lo(v)[1] == 0 else 2)
    return 1


def encode(op, a, pc, labels):
    """List of 32-bit words for one instruction at address pc."""
    target = lambda name: labels[name] - pc
    if op in R:
        f3, f7 = R[op]
        return [r_type(f7, reg(a[2]), reg(a[1]), f3, reg(a[0]), 0x33)]
    if op in I_ALU:
        return [i_type(num(a[2]), reg(a[1]), I_ALU[op], reg(a[0]), 0x13)]
    if op in SHIFT:
        f3, f7 = SHIFT[op]
        sh = num(a[2])
        if not 0 <= sh < 32:
            raise ValueError("bad shift amount: %d" % sh)
        return [r_type(f7, sh, reg(a[1]), f3, reg(a[0]), 0x13)]
    if op in LOAD:
        off, base = mem_operand(a[1])
        return [i_type(off, base, LOAD[op], reg(a[0]), 0x03)]
    if op in STORE:
        off, base = mem_operand(a[1])
        return [s_type(off, reg(a[0]), base, STORE[op])]
    if op in BRANCH:
        return [b_type(target(a[2]), reg(a[1]), reg(a[0]), BRANCH[op])]
    if op in BRANCH_SWAP:
        real, _ = BRANCH_SWAP[op]
        return [b_type(target(a[2]), reg(a[0]), reg(a[1]), BRANCH[real])]
    if op in BRANCH_ZERO:
        real, swap = BRANCH_ZERO[op]
        rs1, rs2 = (0, reg(a[0])) if swap else (reg(a[0]), 0)
        return [b_type(target(a[1]), rs2, rs1, BRANCH[real])]
    if op == "lui":
        return [u_type(num(a[1]), reg(a[0]), 0x37)]
    if op == "auipc":
        return [u_type(num(a[1]), reg(a[0]), 0x17)]
    if op == "jal":
        rd, lab = (reg(a[0]), a[1]) if len(a) == 2 else (1, a[0])
        return [j_type(target(lab), rd)]
    if op == "jalr":
        if len(a) == 1:                                   # jalr rs
            return [i_type(0, reg(a[0]), 0, 1, 0x67)]
        off, base = mem_operand(a[1]) if "(" in a[1] else (num(a[2]), reg(a[1]))
        return [i_type(off, base, 0, reg(a[0]), 0x67)]
    if op == "ecall":
        return [0x00000073]
    if op == "ebreak":
        return [0x00100073]
    # pseudo-instructions
    if op == "nop":
        return [i_type(0, 0, 0, 0, 0x13)]
    if op == "mv":
        return [i_type(0, reg(a[1]), 0, reg(a[0]), 0x13)]
    if op == "not":
        return [i_type(-1, reg(a[1]), 4, reg(a[0]), 0x13)]
    if op == "neg":
        return [r_type(0x20, reg(a[1]), 0, 0, reg(a[0]), 0x33)]
    if op == "seqz":
        return [i_type(1, reg(a[1]), 3, reg(a[0]), 0x13)]
    if op == "snez":
        return [r_type(0, reg(a[1]), 0, 3, reg(a[0]), 0x33)]
    if op == "li":
        rd, v = reg(a[0]), num(a[1])
        if -2048 <= v < 2048:
            return [i_type(v, 0, 0, rd, 0x13)]
        hi, lo = hi_lo(v)
        return [u_type(hi, rd, 0x37)] + ([i_type(lo, rd, 0, rd, 0x13)] if lo else [])
    if op == "j":
        return [j_type(target(a[0]), 0)]
    if op == "jr":
        return [i_type(0, reg(a[0]), 0, 0, 0x67)]
    if op == "ret":
        return [i_type(0, 1, 0, 0, 0x67)]
    if op == "call":                                      # auipc ra + jalr ra
        hi, lo = hi_lo(target(a[0]))
        return [u_type(hi, 1, 0x17), i_type(lo, 1, 0, 1, 0x67)]
    raise ValueError("unknown instruction: " + op)


def parse(paths):
    """List of (label or None, op, args, text) from the source files, in order."""
    items = []
    for path in paths:
        for raw in open(path, encoding="utf-8"):
            line = raw.split("#")[0].strip()
            while line:
                m = re.match(r"([.\w$]+):\s*(.*)", line)       # label
                if m:
                    items.append((m.group(1), None, None, None))
                    line = m.group(2)
                    continue
                if line.startswith("."):                        # directive: ignored
                    break
                op, rest = re.match(r"(\S+)\s*(.*)", line).groups()
                args = [x.strip() for x in rest.split(",")] if rest else []
                items.append((None, op, args, re.sub(r"\s+", " ", line)))
                break
    return items


def main(paths):
    items = parse(paths)
    labels, pc = {}, 0
    for lab, op, args, _ in items:                              # pass 1: addresses
        if lab:
            labels[lab] = pc
        else:
            pc += 4 * size(op, args)
    out, pc = ["// program at address 0x0 (byte addresses, one word = 4 bytes)", "@0"], 0
    for lab, op, args, text in items:                           # pass 2: encoding
        if lab:
            out.append("// %s: (0x%x)" % (lab, labels[lab]))
            continue
        words = encode(op, args, pc, labels)
        for k, w in enumerate(words):
            out.append("%08x // %s" % (w, text if k == 0 else "  (suite)"))
        pc += 4 * len(words)
    print("\n".join(out))


if __name__ == "__main__":
    main(sys.argv[1:])
