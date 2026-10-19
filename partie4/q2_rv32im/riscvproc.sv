 /*
 Authors: Teo Biton
 Date: 07.11.2025
 Description: Simple single-cycle RISC-V processor (RV32IM) for simulation
 
 RISC-V Unprivileged Specifications Volume I: https://riscv.org/technical/specifications/
 Chapters and pages from this Volume are referenced for help (see the one on madoc).

 Partie 4.1: the program is loaded from a text file with $readmemh.
 Partie 4.1.2: immediates sign-extended, load/store address = rs1 + offset,
 x0 hardwired to 0, M extension (RV32IM).
*/

module system;

  // Parameters declaration
  parameter 
    Step      = 10,           // execution time of one instruction
    DataWidth = 32,           // data bus width
    AddrWidth = 12,           // address bus width
    MemSize   = 1<<AddrWidth; // memory size

  // Local parameters declaration
  localparam int unsigned InstrSize = 32; // instructions are on 32 bits
  localparam int unsigned NRegs   = 32;   // number of internal registers

  reg[DataWidth-1:0] memory[0:MemSize-1]; // memory declaration
  reg[InstrSize-1:0] instr;               // instruction register declaration
  reg[AddrWidth-1:0] pc;                  // program counter
  reg[DataWidth-1:0] regs[0:NRegs-1];     // regfile declaration
  reg[AddrWidth-1:0] addr;                // address
  reg[63:0]          prod;                // 64-bit product (MULH, MULHSU, MULHU)

  /*
    Instruction Fields
    Chapter 2.2 Base Instruction Formats
  */

  // instruction identifiers - Pages 15, 16
  `define OPCODE  instr[6:0]     // opcode
  `define F3      instr[14:12]   // funct3
  `define F7      instr[31:25]   // funct7

  // register fields - Pages 15, 16
  `define RS1   instr[19:15]    // source register 1
  `define RS2   instr[24:20]    // source register 2
  `define RD    instr[11:7]     // destination register

  // immediates - Pages 15, 16
  // sign-extended to 32 bits by hand: with $signed(), the immediate was
  // zero-extended, because it is added to an unsigned register
  `define I_IMM   {{20{instr[31]}}, instr[31:20]}               // I-type immediate
  `define S_IMM   {{20{instr[31]}}, instr[31:25], instr[11:7]}  // S-type immediate

  // addresses (for Load and Store instructions)
  // chapter 2.6 Load and Store Instructions: address = rs1 + sign-extended offset,
  // computed in the LW and SW cases with I_IMM and S_IMM

  /*
    Instruction Declarations
    Chapter 24 RV32/64G Instruction Set Listings
    Page 130
  */

  /* Opcodes */
  `define ARITHMETIC        7'b0110011
  `define IMM_ARITHMETIC    7'b0010011
  `define LOAD              7'b0000011
  `define STORE             7'b0100011
  `define EBREAK            7'b1110011

  /* Arithmetic instructions
     Format:    {Funct3, Funct7    } */
  `define ADD   {3'b000, 7'b0000000}
  `define SUB   {3'b000, 7'b0100000}
  `define SLL   {3'b001, 7'b0000000}  // Shift Left
  `define SRL   {3'b101, 7'b0000000}  // Shift Right

  /* Multiplication and division instructions ("M" standard extension)
     Format:    {Funct3, Funct7    } */
  `define MUL     {3'b000, 7'b0000001}  // low 32 bits of rs1 * rs2
  `define MULH    {3'b001, 7'b0000001}  // high 32 bits, signed * signed
  `define MULHSU  {3'b010, 7'b0000001}  // high 32 bits, signed * unsigned
  `define MULHU   {3'b011, 7'b0000001}  // high 32 bits, unsigned * unsigned
  `define DIV     {3'b100, 7'b0000001}  // signed division
  `define DIVU    {3'b101, 7'b0000001}  // unsigned division
  `define REM     {3'b110, 7'b0000001}  // signed remainder
  `define REMU    {3'b111, 7'b0000001}  // unsigned remainder

  /* Load instructions */
  `define LW    3'b010  // Load Word

  /* Store instructions */
  `define SW    3'b010  // Store Word

  /* Arithmetic immediates instructions */
  `define ADDI  3'b000  // Add Immediate
  `define ANDI  3'b111  // And Immediate
  `define ORI   3'b110  // Or Immediate

  /*
    Program loading (partie 4.1)
    The memory is filled with the hexadecimal words of a text file: instr.txt,
    in the simulation folder, unless another file is given when the
    simulation is loaded:  vsim ... +prog=instr2.txt
  */
  string progfile;

  initial begin
    if (!$value$plusargs("prog=%s", progfile))
      progfile = "instr.txt";
    $readmemh(progfile, memory);
  end

  /*
    Reset (start module)
  */
  integer index;

  initial begin
    
    // initialize program counter to 0
    pc = 0;
    // initialize all registers to 0
    for (index = 0; index < NRegs; index = index + 1) begin
      regs[index] = 0;
    end

  end

  /*
    Main cycle for one instruction
  */

  always begin // execution time of one instruction
    
    #Step;
    pc    <= pc + 1;      // increment program counter
    instr <= memory[pc];  // instruction fetch
    addr  <= 0;           // address initial value
    
    case(`OPCODE)        // decode instruction
      `ARITHMETIC: begin // Integer Register-Register Operations - Page 19
        case({`F3, `F7})
          `ADD: regs[`RD] = regs[`RS1] + regs[`RS2];
          `SUB: regs[`RD] = regs[`RS1] - regs[`RS2];
          `SRL: regs[`RD] = regs[`RS1] >> regs[`RS2][4:0];
          `SLL: regs[`RD] = regs[`RS1] << regs[`RS2][4:0];
          // M extension: the operands are extended to 64 bits (sign or zeros)
          // and multiplied, the high word is the result
          `MUL:    regs[`RD] = regs[`RS1] * regs[`RS2];
          `MULH:   begin
                     prod = {{32{regs[`RS1][31]}}, regs[`RS1]} * {{32{regs[`RS2][31]}}, regs[`RS2]};
                     regs[`RD] = prod[63:32];
                   end
          `MULHSU: begin
                     prod = {{32{regs[`RS1][31]}}, regs[`RS1]} * {32'b0, regs[`RS2]};
                     regs[`RD] = prod[63:32];
                   end
          `MULHU:  begin
                     prod = {32'b0, regs[`RS1]} * {32'b0, regs[`RS2]};
                     regs[`RD] = prod[63:32];
                   end
          // division: the special cases of the specification do not raise any exception;
          // if/else rather than ?: which would make the signed division unsigned
          `DIV:    if (regs[`RS2] == 0)
                     regs[`RD] = 32'hFFFFFFFF;                     // division by zero: -1
                   else if (regs[`RS1] == 32'h80000000 && regs[`RS2] == 32'hFFFFFFFF)
                     regs[`RD] = 32'h80000000;                     // overflow: -2^31 / -1
                   else
                     regs[`RD] = $signed(regs[`RS1]) / $signed(regs[`RS2]);
          `DIVU:   if (regs[`RS2] == 0)
                     regs[`RD] = 32'hFFFFFFFF;
                   else
                     regs[`RD] = regs[`RS1] / regs[`RS2];
          `REM:    if (regs[`RS2] == 0)
                     regs[`RD] = regs[`RS1];                       // division by zero: dividend
                   else if (regs[`RS1] == 32'h80000000 && regs[`RS2] == 32'hFFFFFFFF)
                     regs[`RD] = 0;                                // overflow
                   else
                     regs[`RD] = $signed(regs[`RS1]) % $signed(regs[`RS2]);
          `REMU:   if (regs[`RS2] == 0)
                     regs[`RD] = regs[`RS1];
                   else
                     regs[`RD] = regs[`RS1] % regs[`RS2];
          default: $display("erreur: mauvaise instruction arithmétique");
        endcase
      end
      `IMM_ARITHMETIC: begin // Integer Register-Immediate Instructions - Page 18
        case(`F3)
          `ADDI: regs[`RD] = regs[`RS1] + `I_IMM;
          `ANDI: regs[`RD] = regs[`RS1] & `I_IMM;
          `ORI:  regs[`RD] = regs[`RS1] | `I_IMM;
          default: $display("erreur: mauvaise instruction arithmétique immédiate");
        endcase
      end
      `LOAD: begin // Load and Store Instructions - Page 24
        case(`F3)
          `LW: begin
            addr      = regs[`RS1] + `I_IMM;
            regs[`RD] = memory[addr];
          end
          default: $display("erreur: mauvaise instruction load");
        endcase
      end
      `STORE: begin // Load and Store Instructions - Page 24
        case(`F3)
          `SW: begin
            addr         = regs[`RS1] + `S_IMM;
            memory[addr] = regs[`RS2];
          end
          default: $display("erreur: mauvaise instruction store");
        endcase
      end
      // Environment Call and Breakpoints - Page 27
      // Slight change from the spec, Ebreak finishes simulation
      `EBREAK: $finish;
      default: $display("erreur: mauvaise valeur dans op-code");
    endcase
    regs[0] = 0;  // x0 is hardwired to 0 (chapter 2.1)
  end
  
endmodule
