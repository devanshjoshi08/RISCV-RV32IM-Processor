#!/usr/bin/env python3
"""
Simple RV32I hex file disassembler.
Reads a .hex file (one 32-bit word per line) and prints the decoded instruction.
Useful for verifying hand-assembled programs.

Usage: python hex_disasm.py <file.hex>
"""

import sys

OPCODES = {
    0b0110011: "R-type",
    0b0010011: "I-type",
    0b0000011: "LOAD",
    0b0100011: "STORE",
    0b1100011: "BRANCH",
    0b1101111: "JAL",
    0b1100111: "JALR",
    0b0110111: "LUI",
    0b0010111: "AUIPC",
}

R_FUNCT = {
    (0b000, 0b0000000): "add",
    (0b000, 0b0100000): "sub",
    (0b001, 0b0000000): "sll",
    (0b010, 0b0000000): "slt",
    (0b011, 0b0000000): "sltu",
    (0b100, 0b0000000): "xor",
    (0b101, 0b0000000): "srl",
    (0b101, 0b0100000): "sra",
    (0b110, 0b0000000): "or",
    (0b111, 0b0000000): "and",
}

I_FUNCT = {
    0b000: "addi",
    0b001: "slli",
    0b010: "slti",
    0b011: "sltiu",
    0b100: "xori",
    0b110: "ori",
    0b111: "andi",
}

BRANCH_FUNCT = {
    0b000: "beq",
    0b001: "bne",
    0b100: "blt",
    0b101: "bge",
    0b110: "bltu",
    0b111: "bgeu",
}

LOAD_FUNCT = {
    0b000: "lb",
    0b001: "lh",
    0b010: "lw",
    0b100: "lbu",
    0b101: "lhu",
}

STORE_FUNCT = {
    0b000: "sb",
    0b001: "sh",
    0b010: "sw",
}


def sign_extend(value, bits):
    if value & (1 << (bits - 1)):
        value -= 1 << bits
    return value


def decode(word, addr):
    opcode = word & 0x7F
    rd = (word >> 7) & 0x1F
    funct3 = (word >> 12) & 0x7
    rs1 = (word >> 15) & 0x1F
    rs2 = (word >> 20) & 0x1F
    funct7 = (word >> 25) & 0x7F

    op_type = OPCODES.get(opcode, f"UNKNOWN(0b{opcode:07b})")

    if opcode == 0b0110011:  # R-type
        name = R_FUNCT.get((funct3, funct7), "???")
        return f"{name} x{rd}, x{rs1}, x{rs2}"

    elif opcode == 0b0010011:  # I-type ALU
        imm = sign_extend((word >> 20) & 0xFFF, 12)
        if funct3 == 0b101:
            shamt = rs2
            name = "srai" if funct7 & 0x20 else "srli"
            return f"{name} x{rd}, x{rs1}, {shamt}"
        name = I_FUNCT.get(funct3, "???")
        return f"{name} x{rd}, x{rs1}, {imm}"

    elif opcode == 0b0000011:  # LOAD
        imm = sign_extend((word >> 20) & 0xFFF, 12)
        name = LOAD_FUNCT.get(funct3, "???")
        return f"{name} x{rd}, {imm}(x{rs1})"

    elif opcode == 0b0100011:  # STORE
        imm = sign_extend(((word >> 25) << 5) | ((word >> 7) & 0x1F), 12)
        name = STORE_FUNCT.get(funct3, "???")
        return f"{name} x{rs2}, {imm}(x{rs1})"

    elif opcode == 0b1100011:  # BRANCH
        imm = (((word >> 31) & 1) << 12) | (((word >> 7) & 1) << 11) | \
              (((word >> 25) & 0x3F) << 5) | (((word >> 8) & 0xF) << 1)
        imm = sign_extend(imm, 13)
        name = BRANCH_FUNCT.get(funct3, "???")
        target = addr + imm
        return f"{name} x{rs1}, x{rs2}, {imm} (-> 0x{target:04x})"

    elif opcode == 0b1101111:  # JAL
        imm = (((word >> 31) & 1) << 20) | (((word >> 12) & 0xFF) << 12) | \
              (((word >> 20) & 1) << 11) | (((word >> 21) & 0x3FF) << 1)
        imm = sign_extend(imm, 21)
        target = addr + imm
        return f"jal x{rd}, {imm} (-> 0x{target:04x})"

    elif opcode == 0b1100111:  # JALR
        imm = sign_extend((word >> 20) & 0xFFF, 12)
        return f"jalr x{rd}, x{rs1}, {imm}"

    elif opcode == 0b0110111:  # LUI
        imm = word & 0xFFFFF000
        return f"lui x{rd}, 0x{imm >> 12:05x}"

    elif opcode == 0b0010111:  # AUIPC
        imm = word & 0xFFFFF000
        return f"auipc x{rd}, 0x{imm >> 12:05x}"

    return f"??? (0x{word:08x})"


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file.hex>")
        sys.exit(1)

    with open(sys.argv[1]) as f:
        lines = [l.strip() for l in f if l.strip()]

    print(f"{'ADDR':>6}  {'HEX':>10}  INSTRUCTION")
    print("-" * 44)
    for i, line in enumerate(lines):
        word = int(line, 16)
        addr = i * 4
        decoded = decode(word, addr)
        print(f"0x{addr:04x}  0x{word:08x}  {decoded}")


if __name__ == "__main__":
    main()
